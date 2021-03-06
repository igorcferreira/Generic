//
//  MapSearchViewController.m
//  CarTrawler
//
//

#import "QuartzCore/QuartzCore.h"
#import "CarTrawlerAppDelegate.h"
#import "MapSearchViewController.h"
#import "CTForwardGeocoder.h"
#import "CTKmlResult.h"
#import "CustomLocationCell.h"
#import "CTLocation.h"
#import "CustomPlacemark.h"
#import "SearchViewController.h"
#import "SettingsViewController.h"

#import <MapKit/MapKit.h>

#ifdef NSFoundationVersionNumber_iOS_6_1
#define SD_IS_IOS6 (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
#else
#define SD_IS_IOS6 YES
#endif

@interface MapSearchViewController ()
@property (nonatomic, strong) CTHudViewController *hud;
@end

@interface MapSearchViewController (Private)

- (void) zoomToFitMapAnnotations:(MKMapView *) mapView;
- (void) searchButtonPressed;

@end

@implementation MapSearchViewController


#pragma mark -
#pragma mark UIAlertView

- (void) showError:(NSString *)errorMsg {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results Found" message:errorMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alert show];
}

#pragma mark -
#pragma mark Setup UISegmentedControl

- (void) madeSelection:(id)sender {
	UISegmentedControl *thisSegmentedControl = (UISegmentedControl *)sender;
	
	if ( [thisSegmentedControl selectedSegmentIndex] == 0 ) {
		self.searchMap.hidden = NO;
		self.listTable.hidden = YES;
	} else {
		
		[self.listTable reloadData];
		
		self.searchMap.hidden = YES;
		self.listTable.hidden = NO;
	}
}

- (void) setUpSegmentedControl {
    CarTrawlerAppDelegate *appDelegate = (CarTrawlerAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.segmentedControl setTintColor:appDelegate.governingTintColor];
	
	self.navigationItem.titleView = self.segmentedControl;
	
	self.segmentedControl.selectedSegmentIndex = 0;
	[self.segmentedControl addTarget:self action:@selector(madeSelection:) forControlEvents:UIControlEventValueChanged];
}

#pragma mark -
#pragma mark CT API Calls

- (void) locationSearch:(CLLocationCoordinate2D) searchLocation {
	
	// This is a different call to the norm found in CTRQBuilder.  This is because the OTA_VehLocSearchRQ is an alternate configuration
	// that is only used here, so i've been explicit with it and build the ASIRequest from scratch.
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	NSInteger metric = [prefs integerForKey:@"metric"];
	NSInteger searchRadius = [prefs integerForKey:@"searchRadius"];
	if (searchRadius < 1) // Cant pass in a search radius of 0 or less.
	{
		// When the app starts for the first time the value for radius key will be nil, so it'll fall in here.
		// It needs a value to make the request.
		
		searchRadius = 20;
	}
	
	NSLog(@"searchRadius: %ld",(long)searchRadius );
	
	NSString *metricString;
	if (metric == 0)
	{
		metricString = @"miles";  
	}
	else 
	{
		metricString = @"km";
	}

	searchRadius = [prefs integerForKey:@"searchRadius"];
	
	if (searchRadius <= 0) // Cant pass in a search radius of 0  or less.
	{
		searchRadius = 50;
	}
	
	NSString *OTA_VehLocSearchRQString = [NSString stringWithFormat:@"\"VehLocSearchCriterion\":{\"@ExactMatch\":\"true\",\"@ImportanceType\":\"Mandatory\",\"Position\":{\"@Latitude\":\"%.2f\",\"@Longitude\":\"%.2f\"},\"Radius\":{\"@Distance\":\"%li\",\"@DistanceMeasure\":\"%@\"}}", searchLocation.latitude, searchLocation.longitude,(long)searchRadius,metricString];

	NSString *jsonString = [NSString stringWithFormat:@"{%@%@}", [CTRQBuilder buildHeader:kHeader], OTA_VehLocSearchRQString];
	//NSString *jsonString = [NSString stringWithFormat:@"{%@%@}", kHeader, OTA_VehLocSearchRQString];
	
	if (kShowRequest) {
		NSLog(@"Request is \n\n%@\n\n", jsonString);
	}
	
	NSData *requestData = [NSData dataWithBytes: [jsonString UTF8String] length: [jsonString length]];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kCTTestAPI, kOTA_VehLocSearchRQ]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setDelegate:self];
	[request appendPostData:requestData];
	[request setRequestMethod:@"POST"];
	[request setShouldStreamPostDataFromDisk:YES];
	[request setAllowCompressedResponse:YES];
	[request startAsynchronous];
	
	
}

- (void) requestFinished:(ASIHTTPRequest *)request {
	[self.locationResults removeAllObjects];
	NSString *responseString = [request responseString];
	NSLog( @"%@", responseString);
	if (kShowResponse) {
		DLog(@"Response is \n\n%@\n\n", responseString);
	}
	
	NSDictionary *responseDict = [responseString JSONValue];
	
	NSMutableArray *locations = [CTHelper validateResponse:responseDict];
	
	for (int i=  0; i < [locations count]; i++) {
		if ([[locations objectAtIndex:i] isKindOfClass:[CTError class]]) {
			// DLog(@"There has been an error on the map search screen, probably to do with radius' or something.");
			// [self showError:@"No results have been found, please widen the search area in settings and try again."];
			
			// The only time the app find itself in here is if the api call comes back with a CTError.  If that's the case it was probably because the locationManager didn't have a lock
			// and the original lat long was being sent as 0.00/0.00 - send the request once more and see if it does the same.
			
			//DLog(@"Did get response, checking kCLErrorDenied = %i", kCLErrorDenied);
			
			//[self locationSearch:locationManager.location.coordinate];
		} else {
            
			CTLocation *location = (CTLocation *)[locations objectAtIndex:i];
			[self.locationResults addObject:location];
			
			[self.searchMap addAnnotation:location];
		}
	}
	
	[self.listTable reloadData];
	[self zoomToFitMapAnnotations:self.searchMap];
	[self.hud hide];
	//[hud autorelease];
	self.hud = nil;
}

- (void) requestFailed:(ASIHTTPRequest *)request {
	
	if (kShowResponse) {
		DLog(@"Response is %@", [request responseString]);
	}
	
	[self.hud hide];
	//[hud autorelease];
	self.hud = nil;
	NSError *error = [request error];
	DLog(@"Error is %@", error);
}

#pragma mark -
#pragma mark Forward Geocoders

- (void) forwardGeocoderError:(NSString *)errorMessage {
	[self.hud hide];
	//[hud autorelease];
	self.hud = nil;
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
}

- (void) forwardGeocoderFoundLocation {
	
	[self.searchMap removeAnnotations:self.searchMap.annotations];
	
	if(self.forwardGeocoder.status == G_GEO_SUCCESS) {
		
		if ([self.forwardGeocoder.results count] > 1) {
			[self.geocodeResultsTable reloadData];
			[self.geocodeResultsMask setHidden:NO];
			[self.geocodeResultsTable setHidden:NO];
		}
		
		if([self.forwardGeocoder.results count] == 1) {
			
			CTKmlResult *place = [self.forwardGeocoder.results objectAtIndex:0];
			
			CustomPlacemark *placemark = [[CustomPlacemark alloc] initWithRegion:place.coordinateRegion];
			placemark.title = place.address;
			[self.searchMap addAnnotation:placemark];
			
			// Zoom into the location		
			[self.searchMap setRegion:place.coordinateRegion animated:TRUE];
			[self locationSearch:place.coordinate];
		}
		
		[self.hud hide];
		//[hud autorelease];
		self.hud = nil;
	}
	else {
		NSString *message = @"";
		
		switch (self.forwardGeocoder.status) {
			case G_GEO_BAD_KEY:
				message = @"The API key is invalid.";
				break;
				
			case G_GEO_UNKNOWN_ADDRESS:
				message = [NSString stringWithFormat:@"Could not find %@", self.forwardGeocoder.searchQuery];
				break;
				
			case G_GEO_TOO_MANY_QUERIES:
				message = @"Too many queries has been made for this API key.";
				break;
				
			case G_GEO_SERVER_ERROR:
				message = @"Server error, please try again.";
				break;
				

			default:
				break;
		}
		
		[self.hud hide];
		//[hud autorelease];
		self.hud = nil;
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
}

#pragma mark -
#pragma mark UISearchBar Methods

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	self.searchingNearby = NO;

	if(self.forwardGeocoder == nil) {
		self.forwardGeocoder = [[CTForwardGeocoder alloc] initWithDelegate:self];
	}
	// Forward geocode!
	[self.forwardGeocoder findLocation:[searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
	[self.theSearchBar resignFirstResponder];
	[self searchButtonPressed];
	
	self.hud = [[CTHudViewController alloc] initWithTitle:@"Searching"];
	[self.hud show];	

}

#pragma mark -
#pragma mark IBActions

- (IBAction) dismissModalView {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) settingsButtonPressed {
	SettingsViewController *svc = [[SettingsViewController alloc] init];
	[svc setFromMap:YES];
	
//	[FlurryAPI logEvent:@"Step 1: Map search radius refined."];
	
	[self presentViewController:svc animated:YES completion:nil];
}

- (IBAction) currentLocationSearchBtnPressed {
	self.searchingNearby = YES;
	
	self.searchMap.showsUserLocation = YES;
	[self.searchMap removeAnnotations:self.searchMap.annotations];
	
	self.hud = [[CTHudViewController alloc] initWithTitle:@"Searching nearby"];
	[self.hud show];
	
    // Obsolete faking location method
    /*
        #if !(TARGET_IPHONE_SIMULATOR)
     */

	//	[FlurryAPI setLatitude:locationManager.location.coordinate.latitude longitude:locationManager.location.coordinate.longitude horizontalAccuracy:locationManager.location.horizontalAccuracy verticalAccuracy:locationManager.location.verticalAccuracy];
	
		[self locationSearch:self.locationManager.location.coordinate];
	
    // Obsolete faking location method
    /*
     
	#else
		CLLocationCoordinate2D cupertino;
		
		cupertino.latitude = 37.3320;
		cupertino.longitude = -122.029;
		
		[self locationSearch:cupertino];
	#endif
     
     */
}

- (IBAction) searchButtonPressed {
	[self.geocodeResultsMask setHidden:YES];
	[self.geocodeResultsTable setHidden:YES];
	[UIView beginAnimations:@"animSearchBar" context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.20];

    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	if (!self.usingSearchBar) {
		if (self.modalMode) {
			self.theSearchBar.frame = CGRectMake(0.0, 64.0, 320.0, 44);
			[self.theSearchBar becomeFirstResponder];
		} else {
			self.theSearchBar.frame = CGRectMake(0.0, 0.0, 320.0, 44);
			[self.theSearchBar becomeFirstResponder];
		}

	} else {
		if (self.modalMode) {
			self.theSearchBar.frame = CGRectMake(0.0, 20.0, 320.0, 44);
			[self.theSearchBar resignFirstResponder];
		} else {
			self.theSearchBar.frame = CGRectMake(0.0,-44.0, 320.0, 44);
			[self.theSearchBar resignFirstResponder];
		}
		
	}
	self.usingSearchBar = !self.usingSearchBar;
	
//	[FlurryAPI logEvent:@"Step 1: Map searched by place name."];
	
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark UIViewController Stuff

- (id) init {
    self=[super initWithNibName:@"MapSearchViewController" bundle:nil];
	// … give ivars initial values…
    return self;
}

- (id) initWithNibName:(NSString *)n bundle:(NSBundle *)b {
	return [self init];
}

- (void) viewDidLoad {
	[super viewDidLoad];
    
    CarTrawlerAppDelegate *appDelegate = (CarTrawlerAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.navigationController.navigationBar.tintColor = appDelegate.governingTintColor;

	self.title = @"Locations";
	self.navigationItem.titleView = [CTHelper getNavBarLabelWithTitle:@"Locations"];
	
	self.locationResults = nil;
	self.locationResults = [[NSMutableArray alloc] init];
	
	if (self.modalMode) { // Set up the rest of the interface elements that are out of whack for a modal view...
		[self.searchMap setFrame:CGRectMake(0, 44, 320, 480)];
		[self.listTable setFrame:CGRectMake(0, 64, 320, 320)];
		
		//[self.theSearchBar setFrame:CGRectMake(0, 0, 320, self.theSearchBar.frame.size.height)];
		
		UIButton *closeBtn = [[UIButton alloc] init];
		closeBtn = [CTHelper getSmallGreenUIButtonWithTitle:@"Close"];
        
		[self.settingsButton setFrame:CGRectMake(280, 425, 35, 35)];
        
        
        if (SD_IS_IOS6) {
            [closeBtn setFrame:CGRectMake(85, 400, closeBtn.frame.size.width, closeBtn.frame.size.height)];
            [self.segmentedControl setFrame:CGRectMake(58, 7, 204, 30)];
            self.modalSearchName.image = [UIImage imageNamed:@"button_search_25x25.png"];
            self.modalSearchLocation.image = [UIImage imageNamed:@"button_map_25x25.png"];
            
        } else {
            [closeBtn setFrame:CGRectMake(85, [[UIScreen mainScreen] bounds].size.height - closeBtn.frame.size.height - 10, closeBtn.frame.size.width, closeBtn.frame.size.height)];
            [self.segmentedControl setFrame:CGRectMake(58, 22, 204, 30)];
            self.modalSearchName.image = [UIImage imageNamed:@"searchIcon.png"];
            self.modalSearchLocation.image = [UIImage imageNamed:@"compass.png"];
        }
        
		[closeBtn addTarget:self action:@selector(dismissModalView) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:closeBtn];
        
	} else {
		self.modalNavBar.hidden = YES;
		[self.theSearchBar setFrame:CGRectMake(0, -44.0, 320, self.theSearchBar.frame.size.height)];
		UIBarButtonItem *currentLocationSearchBtn = [UIBarButtonItem alloc];
		
        if (SD_IS_IOS6) {
            self.searchBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_search_25x25.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(searchButtonPressed)];
            currentLocationSearchBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_map_25x25.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(currentLocationSearchBtnPressed)];
        } else {
            self.searchBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"searchIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(searchButtonPressed)];            
            currentLocationSearchBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"compass.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(currentLocationSearchBtnPressed)];
        }
		self.navigationItem.leftBarButtonItem = currentLocationSearchBtn;
		self.navigationItem.rightBarButtonItem = self.searchBtn;
	}

	
	[self setUpSegmentedControl];
	
	[self.geocodeResultsMask setHidden:YES];
	[self.geocodeResultsTable setHidden:YES];
	
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	
	self.locationManager.delegate = self;
	
	if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
		[self.locationManager requestWhenInUseAuthorization];
	}
	
	[self.locationManager startUpdatingLocation];
	
	self.searchMap.showsUserLocation = YES;
	self.usingSearchBar = NO;
	
	[self.listTable setHidden:YES];
	
	[self currentLocationSearchBtnPressed];
	
    
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Load Search View Stuff

- (void) sendLocationSelectedNotification:(CTLocation *)l {
	DLog(@"You pressed %@", l.locationName);
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	[dict setObject:l forKey:@"selectedLocation"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CTLocationSelected" object:self userInfo:dict];
	[self dismissModalView];
}

- (void) populateSearchForm:(CTLocation *)l {
	
	// This is simple to follow.  The referringFieldValue is the tag from the SearchViewController map button.
	// Trigger the notification depending on which (or if) it is or else push the standard SVC.
	if (self.modalMode) {
		if (self.referringFieldValue == 0){
			DLog(@"Sending pick up");
			[self sendLocationSelectedNotification:l];
			
		} else if (self.referringFieldValue == 1) {
			DLog(@"Sending drop off");
			[self sendLocationSelectedNotification:l];
			
		}
	} else {
		SearchViewController *svc = [[SearchViewController alloc] init];
		[svc setSelectedNearbyLocation:l];
		// These two bools will force dispaly the green check mark when the screen loads. 
		[svc setPickupLocationSet:YES];
		[svc setDropoffLocationSet:YES];
		[svc setSetFromLocations:YES];
		
		[self.navigationController pushViewController:svc animated:YES];
	}
}

#pragma mark -
#pragma mark UITableView Stuff

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (tableView == self.listTable) {
		if ([self.locationResults count] > 0) {
			return [self.locationResults count];
		} else {
			return 1;
		}
	} else {
		if ([self.forwardGeocoder.results count] > 0) {
			return [self.forwardGeocoder.results count];
		} else {
			return 1;
		}
	}
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (tableView == self.listTable) {
		
		static NSString *CellIdentifier = @"ListItemCell";
		
		CustomLocationCell *cell = (CustomLocationCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		if (cell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomLocationCell" owner:self options:nil];
			cell = (CustomLocationCell *)[nib objectAtIndex:0];
			
		}
		
		if ([self.locationResults count] > 0) {
			CTLocation *l = (CTLocation *)[self.locationResults objectAtIndex:indexPath.row];
			
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.tag = indexPath.row;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			cell.locationIcon.image = [UIImage imageNamed:l.iconImage];
			
			cell.locationNameLabel.text = [l.locationName capitalizedString];
			// This is weird but catches the empty address problem
			cell.locationAddressLabel.text = [l.addressLine description];
			cell.locationDistanceLabel.text = [NSString stringWithFormat:@"%@ %@", l.distance, l.distanceMetric];
			
		} else {
			cell.locationNameLabel.text = @"No locations, please try again.";
			cell.locationDistanceLabel.hidden = YES;
			cell.locationAddressLabel.hidden = YES;
			cell.locationIcon.hidden = YES;
		}
		
		return cell;
		
	} else {
		static NSString *CellIdentifier = @"Cell";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		}
		
		CTKmlResult *place = [self.forwardGeocoder.results objectAtIndex:indexPath.row];
		[cell.textLabel setText:[NSString stringWithFormat:@"%@", place.address]];
		[cell.textLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
		return cell;
	}
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (tableView == self.listTable) 
	{
		// Have selected location and now we're pushing a search view controller
		if ([self.locationResults count] != 0) // If its empty then dnt try and get an object out of the array.
		{
			CTLocation *l = (CTLocation *)[self.locationResults objectAtIndex:indexPath.row];
			[self populateSearchForm:l];
		}
		
		
	} else {
		[self.geocodeResultsTable setHidden:YES];
		[self.geocodeResultsMask setHidden:YES];
		
		CTKmlResult *place = [self.forwardGeocoder.results objectAtIndex:indexPath.row];
		CustomPlacemark *placemark = [[CustomPlacemark alloc] initWithRegion:place.coordinateRegion];
		placemark.title = place.address;
		[self.searchMap addAnnotation:placemark];
		
		[self locationSearch:place.coordinate];
	}
	
//	[FlurryAPI logEvent:@"Step 1: Location selected from map list."];
}

#pragma mark -
#pragma mark CoreLocation Methods

- (void) locationUpdate:(CLLocation *)location {
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	Error(@"Location manager error: %@", [error description]);
	
	DLog(@"before the check kCLLErrorDenied is %li", kCLErrorDenied);
	if (kCLErrorDenied) {
		[CTHelper showAlert:@"Location Services Unavailable" message:@"You can re-enable Location Services for this app in the Location Services section of the iPhone's Settings."];
	}
	return;
}

- (void) locationManager: (CLLocationManager *) manager didUpdateToLocation: (CLLocation *) newLocation fromLocation: (CLLocation *) oldLocation  {
	//[self locationUpdate:newLocation];
}

- (void) mapViewDidStopLocatingUser:(MKMapView *)mapView {
	DLog(@" ? ");
}

#pragma mark -
#pragma mark MKMapView Stuff

- (void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	CTLocation *l = (CTLocation *)[view annotation];
	[self populateSearchForm:l];
//	[FlurryAPI logEvent:@"Step 1: Location selected from map annotation."];
}

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(CTLocation *)annotation {
    if( [[annotation title] isEqualToString:@"Current Location"] ) {
		return nil;
	}
	if([annotation isKindOfClass:[CustomPlacemark class]])
	{
		MKPinAnnotationView *newAnnotation = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[annotation title]];
		newAnnotation.pinColor = MKPinAnnotationColorGreen;
		newAnnotation.animatesDrop = YES; 
		newAnnotation.canShowCallout = YES;
		newAnnotation.enabled = YES;
		
		return newAnnotation;
	} else {
		MKAnnotationView *annotationView = [aMapView dequeueReusableAnnotationViewWithIdentifier:@"spot"];
		if(!annotationView) {
			annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"spot"];
			annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			annotationView.enabled = YES;
			annotationView.canShowCallout = YES;
			
		}
		annotationView.image = [UIImage imageNamed:annotation.iconImage];
		return annotationView;
	}
}

- (void) zoomToFitMapAnnotations:(MKMapView *) mapView {
	if (!self.searchingNearby) {
		self.searchMap.showsUserLocation = NO;	
	}
	if([mapView.annotations count] == 0)
        return;
	
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
	
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
	
    for(CTLocation *annotation in mapView.annotations) {
        
        //NSLog(@"%f - %f", annotation.coordinate.latitude, annotation.coordinate.longitude); // here I control IF app parses all the values of coordinates

        
			topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
			topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
			
			bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
			bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
		
    }
	
    MKCoordinateRegion region;
	
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.1; // Add a little extra space on the sides
	region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1; // Add a little extra space on the sides
	
    region = [mapView regionThatFits:region];
    [mapView setRegion:region animated:YES];
}

@end

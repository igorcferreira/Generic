//
// Copyright 2014 Etrawler
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//
//  Car.h
//  CarTrawler
//
//

@class Vendor;

@interface Car : NSObject
{
	// Vehicle Info
	
	BOOL isAvailable;
	BOOL isAirConditioned;
	
	NSString	*transmissionType;
	NSString	*fuelType;
	NSString	*driveType;
	NSString	*__weak passengerQty;
	NSInteger	passengerQtyInt;
	NSString	*baggageQty;
	NSString	*code;
	NSString	*codeContext;
	NSString	*vehicleCategory;
	NSString	*doorCount;
	NSInteger	vehicleClassSize;
	NSString	*vehicleMakeModelName;
	NSString	*vehicleMakeModelCode;
	NSString	*pictureURL;
	NSString	*vehicleAssetNumber;
	
	// Rate info for this vehicle
	
	NSMutableArray	*vehicleCharges; // These are extras like breakdown assist etc
	NSString	*rateQualifier;
	NSString	*rateTotalAmount;
	NSString	*estimatedTotalAmount;
	NSString	*currencyCode; // This should be a CTCurrency?
	
	NSString	*refType;
	NSString	*refID;
	NSString	*refIDContext;
	NSString	*refTimeStamp;
	NSString	*refURL;
	
	NSString	*orderBy;
	int			orderIndex;
	BOOL		needCCInfo;
	NSString	*theDuration;
	BOOL		insuranceAvailable;
	
	NSMutableArray	*fees; // This array contains 3 dictionarys for each code (6, 22, 23) Ignore the ones outside of TPA_Extension...
	
	NSString	*currencyExchangeRate;
	NSString	*currencyExchangeRate23;
	
	NSMutableArray	*pricedCoverages;
	NSMutableArray	*extraEquipment;
	
	Vendor		*vendor;
	
	NSNumber	*totalPriceForThisVehicle;
}

@property (nonatomic, strong) NSNumber *totalPriceForThisVehicle;
@property (nonatomic, strong) Vendor *vendor;
@property (nonatomic, assign) int orderIndex;
@property (nonatomic, strong) NSMutableArray *extraEquipment;
@property (nonatomic, assign) BOOL insuranceAvailable;
@property (nonatomic, assign) BOOL isAvailable;
@property (nonatomic, assign) BOOL isAirConditioned;
@property (nonatomic, copy) NSString *transmissionType;
@property (nonatomic, copy) NSString *fuelType;
@property (nonatomic, copy) NSString *driveType;
@property (nonatomic, weak) NSString *passengerQty;
@property (nonatomic, assign) NSInteger passengerQtyInt;
@property (nonatomic, copy) NSString *baggageQty;
@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *codeContext;
@property (nonatomic, copy) NSString *vehicleCategory;
@property (nonatomic, copy) NSString *doorCount;
@property (nonatomic) NSInteger vehicleClassSize;
@property (nonatomic, copy) NSString *vehicleMakeModelName;
@property (nonatomic, copy) NSString *vehicleMakeModelCode;
@property (nonatomic, copy) NSString *pictureURL;
@property (nonatomic, copy) NSString *vehicleAssetNumber;
@property (nonatomic, strong) NSMutableArray *vehicleCharges;
@property (nonatomic, copy) NSString *rateQualifier;
@property (nonatomic, copy) NSString *rateTotalAmount;
@property (nonatomic, copy) NSString *estimatedTotalAmount;
@property (nonatomic, copy) NSString *currencyCode;
@property (nonatomic, copy) NSString *refType;
@property (nonatomic, copy) NSString *refID;
@property (nonatomic, copy) NSString *refIDContext;
@property (nonatomic, copy) NSString *refTimeStamp;
@property (nonatomic, copy) NSString *refURL;
@property (nonatomic, copy) NSString *orderBy;
@property (nonatomic, assign) BOOL needCCInfo;
@property (nonatomic, copy) NSString *theDuration;
@property (nonatomic, strong) NSMutableArray *fees;
@property (nonatomic, copy) NSString *currencyExchangeRate;
@property (nonatomic, copy) NSString *currencyExchangeRate23;
@property (nonatomic, strong) NSMutableArray *pricedCoverages;

- (NSNumber *) calculateTotalPriceForThisCar;
- (id) initFromVehicleDictionary:(NSDictionary *)vehicleDictionary;

@end





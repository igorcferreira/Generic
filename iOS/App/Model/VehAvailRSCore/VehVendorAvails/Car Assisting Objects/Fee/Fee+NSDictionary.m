//
//  Fee+NSDictionary.m
//  CarTrawler
//
//  Created by Igor Ferreira on 8/1/15.
//  Copyright (c) 2015 www.cartrawler.com. All rights reserved.
//

#import "Fee+NSDictionary.h"

@implementation Fee (NSDictionary)

+ (instancetype) feeWithDictionary:(NSDictionary *)dictionary
{
	NSString *amount = [dictionary objectForKey:@"@Amount"];
	NSString *currencyCode = [dictionary objectForKey:@"@CurrencyCode"];
	NSString *purpose = [dictionary objectForKey:@"@Purpose"];
	NSString *purposeDescription = [Fee parsePurpose:purpose];

	Fee *fee = [[Fee alloc] initWithAmount:amount currencyCode:currencyCode andPurpose:purpose andPurposeDescription:purposeDescription];
	
	return fee;
}

+ (NSString *)parsePurpose:(NSString *)purpose
{
	if ([purpose isEqualToString:@"22"]) {
		return @"Deposit fee, taken at confirmation.";
	} else if ([purpose isEqualToString:@"23"]) {
		return @"Fee to pay on arrival.";
	} else if ([purpose isEqualToString:@"6"]) {
		return @"Cartrawler booking fee.";
	}
	return @"";
}

@end

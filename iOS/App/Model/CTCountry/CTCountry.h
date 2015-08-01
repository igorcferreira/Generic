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
//  CTCountry.h
//  CarTrawler
//
//


@interface CTCountry : NSObject {

	NSString	*isoCountryName;
	NSString	*isoCountryCode;
	NSString	*isoDialingCode;
	
	NSString	*currencyName;
	NSString	*currencyCode;
	NSString	*currencySymbol;

}

- (id) initFromArray:(NSMutableArray *)csvRow;

@property (nonatomic, copy) NSString *currencyName;
@property (nonatomic, copy) NSString *currencyCode;
@property (nonatomic, copy) NSString *currencySymbol;
@property (nonatomic, copy) NSString *isoCountryName;
@property (nonatomic, copy) NSString *isoCountryCode;
@property (nonatomic, copy) NSString *isoDialingCode;

@end

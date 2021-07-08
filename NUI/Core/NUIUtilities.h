//
//  NUIUtilities.h
//  NUI
//
//  Created by Tom Benner on 11/22/12.
//  Copyright (c) 2012 Tom Benner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NUISettings.h"

@interface NUIUtilities : NSObject

+ (NSDictionary*)titleTextAttributesForClass:(NSString*)className;
+ (NSDictionary*)titleTextAttributesForClass:(NSString*)className withSuffix:(NSString*) suffix;
+ (NSMutableAttributedString *)generateStylesFromHtml:(NSString *)htmlText originalFont:(UIFont *)originalFont adjustsFontForContentSizeCategory:(BOOL *) adjustsFontForContentSizeCategory;
+ (NSArray *)generateStylesAndLinksFromHtml:(NSString *)htmlText originalFont:(UIFont *)originalFont adjustsFontForContentSizeCategory:(BOOL *) adjustsFontForContentSizeCategory;

@end

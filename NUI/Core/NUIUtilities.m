//
//  NUIUtilities.m
//  NUI
//
//  Created by Tom Benner on 11/22/12.
//  Copyright (c) 2012 Tom Benner. All rights reserved.
//

#import "NUIUtilities.h"

@implementation NUIUtilities

+ (UIFont *)calculateFontToAdjust:(UIFont *)customFont originalFont:(UIFont *)originalFont adjustsFontForContentSizeCategory:(BOOL *) adjustsFontForContentSizeCategory {
    if (adjustsFontForContentSizeCategory && !customFont) {
        return nil;
    }

    UIFont *fontToScale = originalFont;
    if (customFont) {
        fontToScale = customFont;
    }

    UIFont *newFont = [[UIFontMetrics defaultMetrics] scaledFontForFont:fontToScale];
    return newFont;
}

+ (NSDictionary *)titleTextAttributesForClass:(NSString *)className withSuffix:(NSString *)suffix
{
    NSMutableDictionary *titleTextAttributes = [NSMutableDictionary dictionary];
    
    NSString *fontColorSelector = [NUIUtilities selector:@"font-color" withSuffix:suffix];
    NSString *textShadowColorSelector = [NUIUtilities selector:@"text-shadow-color" withSuffix:suffix];
    NSString *textShadowOffsetSelector = [NUIUtilities selector:@"text-shadow-offset" withSuffix:suffix];
    
    if ([NUISettings hasFontPropertiesWithClass:className]) {
        UIFont *font = [NUISettings getFontWithClass:className];
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
        [titleTextAttributes setObject:font forKey:NSFontAttributeName];
#else
        [titleTextAttributes setObject:font forKey:UITextAttributeFont];
#endif
    }
    
    if ([NUISettings hasProperty:fontColorSelector withClass:className]) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
        [titleTextAttributes setObject:[NUISettings getColor:fontColorSelector withClass:className] forKey:NSForegroundColorAttributeName];
#else
        [titleTextAttributes setObject:[NUISettings getColor:fontColorSelector withClass:className] forKey:UITextAttributeTextColor];
#endif
    }
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    if ([NUISettings hasProperty:textShadowColorSelector withClass:className] || [NUISettings hasProperty:textShadowOffsetSelector withClass:className]) {
        NSShadow *shadow = [NSShadow new];
        
        if ([NUISettings hasProperty:textShadowColorSelector withClass:className]) {
            shadow.shadowColor = [NUISettings getColor:textShadowColorSelector withClass:className];
        }
        
        if ([NUISettings hasProperty:textShadowOffsetSelector withClass:className]) {
            shadow.shadowOffset = [NUISettings getSize:textShadowOffsetSelector withClass:className];
        }
        
        [titleTextAttributes setObject:shadow forKey:NSShadowAttributeName];
    }
#else
    if ([NUISettings hasProperty:textShadowColorSelector withClass:className]) {
        [titleTextAttributes setObject:[NUISettings getColor:textShadowColorSelector withClass:className] forKey:UITextAttributeTextShadowColor];
    }
    
    if ([NUISettings hasProperty:textShadowOffsetSelector withClass:className]) {
        [titleTextAttributes setObject:[NSValue valueWithUIOffset:[NUISettings getOffset:textShadowOffsetSelector withClass:className]] forKey:UITextAttributeTextShadowOffset];
    }
#endif
    
    return titleTextAttributes;
}

+ (NSDictionary*)titleTextAttributesForClass:(NSString*)className
{
    return [NUIUtilities titleTextAttributesForClass:className withSuffix:nil];
}

+ (NSString*)selector:(NSString*)selector withSuffix:(NSString*)suffix
{
    if (suffix) {
        return [NSString stringWithFormat:@"%@-%@", selector, suffix];
    }
    
    return selector;
}

+ (NSMutableAttributedString *)generateStylesFromHtml:(NSString *)htmlText originalFont:(UIFont *)originalFont adjustsFontForContentSizeCategory:(BOOL *) adjustsFontForContentSizeCategory {
    NSRegularExpression *outerSpanRegex = [NSRegularExpression regularExpressionWithPattern:@"<span[^>]*>.*<.*</span>" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray *matches = [outerSpanRegex matchesInString:htmlText options:0 range:NSMakeRange(0, htmlText.length)];
    
    NSString *surroundingNuiClass;
    for (NSTextCheckingResult *match in matches) {
        NSString *matchedString = [htmlText substringWithRange:match.range];
        surroundingNuiClass = [self getClassNameOnSpanTag:matchedString];
    }

    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [[NSMutableDictionary alloc] init];
    
    if (surroundingNuiClass != nil && ([NUISettings hasProperty:@"font-name" withClass:surroundingNuiClass] || [NUISettings hasProperty:@"font-size" withClass:surroundingNuiClass])) {
        UIFont* newFont = [NUISettings getFontWithClass:surroundingNuiClass];
        attributes[NSFontAttributeName] = [self calculateFontToAdjust:newFont originalFont:originalFont adjustsFontForContentSizeCategory:adjustsFontForContentSizeCategory];
    }
    
    if (surroundingNuiClass != nil && [NUISettings hasProperty:@"font-color" withClass:surroundingNuiClass]) {
        attributes[NSForegroundColorAttributeName] = [NUISettings getColor:@"font-color" withClass:surroundingNuiClass];
    }

    NSMutableAttributedString *attributedStringResult = [[NSMutableAttributedString alloc] initWithString:htmlText attributes:attributes];

    NSRegularExpression *innerSpanRegex = [NSRegularExpression regularExpressionWithPattern:@"<span[^>]*>[^<]*</span>" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    matches = [innerSpanRegex matchesInString:htmlText options:0 range:NSMakeRange(0, htmlText.length)];

    UIFont *font;
    UIColor *color;
    for (NSTextCheckingResult *match in matches) {
        NSString *matchedString = [htmlText substringWithRange:match.range];

        NSString *className = [self getClassNameOnSpanTag:matchedString];
        if (className == nil) {
            continue;
        }
        
        if (![NUISettings hasProperty:@"font-name" withClass:className] && ![NUISettings hasProperty:@"font-size" withClass:className]) {
            continue;
        }
        
        font = [NUISettings getFontWithClass:className];
        font = [self calculateFontToAdjust:font originalFont:originalFont adjustsFontForContentSizeCategory:adjustsFontForContentSizeCategory];
        [attributedStringResult addAttribute:NSFontAttributeName value:font range:match.range];
        
        if (![NUISettings hasProperty:@"font-color" withClass:className]) {
            continue;
        }
        
        color = [NUISettings getColor:@"font-color" withClass:className];
        [attributedStringResult addAttribute:NSForegroundColorAttributeName value:color range:match.range];
    }

    attributedStringResult = [self removeTags:attributedStringResult withTagName:@"span"];

    return attributedStringResult;
}

+ (NSString *)getClassNameOnSpanTag:(NSString *)spanTag
{
    NSArray *items = [spanTag componentsSeparatedByString:@"<span"];
    if (items.count < 2) {
        return nil;
    }
    
    NSString *attributePart = items[1];
    items = [attributePart componentsSeparatedByString:@"="];
    if (items.count < 2) {
        return nil;
    }

    NSString *attributeName = [items[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([attributeName isEqualToString:@"class"]) {
        attributePart = [items[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *attributeValue = @"";
        BOOL hasStartedClassName = NO;
        for (NSInteger index = 0; index < attributePart.length; index++) {
            unichar ch = [attributePart characterAtIndex:index];
            if (ch == '\'') {
                if (!hasStartedClassName) {
                    hasStartedClassName = YES;
                } else {
                    break;
                }
            } else {
                attributeValue = [attributeValue stringByAppendingString:[NSString stringWithFormat:@"%c", ch]];
            }
        }
        return attributeValue;
    }

    return nil;
}

+ (NSMutableAttributedString *)removeTags:(NSMutableAttributedString*)attributedStringResult withTagName:tagName
{
    NSString* startTag = [@"<" stringByAppendingString:tagName];
    NSString* startTagWithAttributes = [startTag stringByAppendingString:@"[^>]*>"];
    NSString* endTag = [@"</" stringByAppendingString:tagName];
    endTag = [endTag stringByAppendingString:@">"];
    while ([attributedStringResult.string containsString:startTag] || [attributedStringResult.string containsString:endTag]) {
        NSRange rangeOfTag = [attributedStringResult.string rangeOfString:startTagWithAttributes options:NSRegularExpressionSearch];
        [attributedStringResult replaceCharactersInRange:rangeOfTag withString:@""];
        rangeOfTag = [attributedStringResult.string rangeOfString:endTag];
        [attributedStringResult replaceCharactersInRange:rangeOfTag withString:@""];
    }
    return attributedStringResult;
}

+ (NSArray *)generateStylesAndLinksFromHtml:(NSString *)htmlText originalFont:(UIFont *)originalFont adjustsFontForContentSizeCategory:(BOOL *) adjustsFontForContentSizeCategory
{
    NSMutableAttributedString *attributedText = [NUIUtilities generateStylesFromHtml:htmlText originalFont:originalFont adjustsFontForContentSizeCategory:adjustsFontForContentSizeCategory];
    NSString *changedHtmlText = attributedText.string;
    
    // Searching for the first link with class name
    NSRegularExpression *anchorRegex = [NSRegularExpression regularExpressionWithPattern:@"<a[\\s]+href='([^']*)'[\\s]+class='([^']*)'>([^<]*)</a>" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *matches = [anchorRegex matchesInString:changedHtmlText options:0 range:NSMakeRange(0, changedHtmlText.length)];
    
    UIColor *linkColor;
    for (NSTextCheckingResult *match in matches) {
        NSString *matchedLink = [changedHtmlText substringWithRange:[match rangeAtIndex:1]];
        NSString *className = [changedHtmlText substringWithRange:[match rangeAtIndex:2]];
        
        if ([NUISettings hasProperty:@"font-color" withClass:className]) {
            linkColor = [NUISettings getColor:@"font-color" withClass:className];
        }
        
        NSString *matchedString = [changedHtmlText substringWithRange:[match rangeAtIndex:3]];
        NSRange range = [attributedText.string rangeOfString:matchedString];
        [attributedText addAttribute:NSLinkAttributeName value:matchedLink range:range];
    }
    
    // If available, searching for remaining links (they must not have class names)
    NSRegularExpression *anchorRegexRemaning = [NSRegularExpression regularExpressionWithPattern:@"<a[\\s]+href='([^']*)'>([^<]*)</a>" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *matchesRemaining = [anchorRegexRemaning matchesInString:changedHtmlText options:0 range:NSMakeRange(0, changedHtmlText.length)];
    
    for (NSTextCheckingResult *match in matchesRemaining) {
        NSString *matchedLink = [changedHtmlText substringWithRange:[match rangeAtIndex:1]];
        NSString *matchedString = [changedHtmlText substringWithRange:[match rangeAtIndex:2]];
        NSRange range = [attributedText.string rangeOfString:matchedString];
        [attributedText addAttribute:NSLinkAttributeName value:matchedLink range:range];
    }
    
    attributedText = [self removeTags:attributedText withTagName:@"a"];
    
    if (linkColor != nil) {
        return @[attributedText, @{NSForegroundColorAttributeName: linkColor}];
    }
    
    return @[attributedText];
}

@end

#import "UITextView+NUI.h"

@implementation UITextView (NUI)

@dynamic nuiHtmlText;

- (void)initNUI
{
    if (!self.nuiClass) {
        self.nuiClass = @"TextView";
    }
}

- (void)applyNUI
{
    if ([self isMemberOfClass:[UITextView class]] || self.nuiClass) {
        [self initNUI];
        if (![self.nuiClass isEqualToString:kNUIClassNone]) {
            [NUIRenderer renderTextView:self withClass:self.nuiClass];
        }
    }
    self.nuiApplied = YES;
}

- (void)override_UITextView_didMoveToWindow
{
    if (!self.isNUIApplied) {
        [self applyNUI];
    }
    [self override_UITextView_didMoveToWindow];
}

- (void)setNuiHtmlText:(NSString *)nuiHtmlText
{
    NSArray *attributes = [NUIUtilities generateStylesAndLinksFromHtml:nuiHtmlText originalFont:self.font adjustsFontForContentSizeCategory:self.adjustsFontForContentSizeCategory];
    if (attributes == nil) {
        return;
    }
    
    if (attributes.count > 0) {
        self.attributedText = attributes[0];
    }
    
    if (attributes.count > 1) {
        self.linkTextAttributes = attributes[1];
    }
}

@end

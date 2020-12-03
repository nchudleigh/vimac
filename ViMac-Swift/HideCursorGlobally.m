//
//  HideCursorGlobally.m
//  Vimac
//
//  Created by Dexter Leng on 1/1/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

#import "HideCursorGlobally.h"

@implementation HideCursorGlobally

+ (void) hide {
    void CGSSetConnectionProperty(int, int, CFStringRef, CFBooleanRef);
    int _CGSDefaultConnection();
    CFStringRef propertyString;

    // Hack to make background cursor setting work
    propertyString = CFStringCreateWithCString(NULL, "SetsCursorInBackground", kCFStringEncodingUTF8);
    CGSSetConnectionProperty(_CGSDefaultConnection(), _CGSDefaultConnection(), propertyString, kCFBooleanTrue);
    CFRelease(propertyString);
    // Hide the cursor and wait
    CGDisplayHideCursor(kCGDirectMainDisplay);
}

+ (void) unhide {
    CGDisplayShowCursor(CGMainDisplayID());
}
@end

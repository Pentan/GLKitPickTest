//
//  GKPAppDelegate.h
//  GLKitPickTest
//
//  Created by Satoru NAKAJIMA on 2013/03/04.
//  Copyright (c) 2013年 Satoru NAKAJIMA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GKPPickupView;

@interface GKPAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet GKPPickupView *glView;

- (IBAction)rearrangeObject:(id)sender;

@end

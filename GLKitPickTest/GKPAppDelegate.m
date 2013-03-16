//
//  GKPAppDelegate.m
//  GLKitPickTest
//
//  Created by Satoru NAKAJIMA on 2013/03/04.
//  Copyright (c) 2013年 Satoru NAKAJIMA. All rights reserved.
//

#import "GKPAppDelegate.h"
#import "GKPPickupView.h"

@implementation GKPAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (IBAction)rearrangeObject:(id)sender
{
	[self.glView rearrangeObjects];
}

@end

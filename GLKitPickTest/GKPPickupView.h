//
//  GKPPickupView.h
//  GLKitPickTest
//
//  Created by Satoru NAKAJIMA on 2013/03/04.
//  Copyright (c) 2013年 Satoru NAKAJIMA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class GKPRenderer;

@interface GKPPickupView : NSOpenGLView
{
	CVDisplayLinkRef displayLink;
	GKPRenderer *renderer;
}
- (void)rearrangeObjects;
@end

//
//  GKPPickupView.m
//  GLKitPickTest
//
//  Created by Satoru NAKAJIMA on 2013/03/04.
//  Copyright (c) 2013年 Satoru NAKAJIMA. All rights reserved.
//

#import <OpenGL/OpenGL.h>
#import <GLKit/GLKit.h>
#import "GKPPickupView.h"
#import "GKPRenderer.h"
#import "GKP3DObject.h"

// private methods
@interface GKPPickupView ()
{
}
- (void)renderView;
@end


/////
@implementation GKPPickupView

static CVReturn GKPDisplayLinkCallback(CVDisplayLinkRef displayLink,
									   const CVTimeStamp *inNow,
									   const CVTimeStamp *inOutputTime,
									   CVOptionFlags flagsIn,
									   CVOptionFlags *flagsOut,
									   void *displayLinkContext)
{
	// Now useing ARC
	//NSAutoreleasePool *ap = [[NSAutoreleasePool alloc] init];
	@autoreleasepool {
		GKPPickupView *viewref = (__bridge GKPPickupView*)displayLinkContext;
		[viewref renderView];
	}
	//[ap release];
	return kCVReturnSuccess;
}

- (void)awakeFromNib
{
	NSOpenGLPixelFormatAttribute attrs[] = {
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
		0
	};
	
	NSOpenGLPixelFormat *pxfrmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:pxfrmt shareContext:nil];
	
	[self setPixelFormat:pxfrmt];
	[self setOpenGLContext:context];
}

- (void)prepareOpenGL
{
	[super prepareOpenGL];
	
	[[self openGLContext] makeCurrentContext];
	
	// GL initialize
	renderer = [[GKPRenderer alloc] init];
	
	// Display link
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	CVDisplayLinkSetOutputCallback(displayLink, &GKPDisplayLinkCallback, (__bridge void*)self);
	
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPF = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPF);
	
	CVDisplayLinkStart(displayLink);
}

- (void)reshape
{
	[super reshape];
	
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	[renderer resizeWithWidth:NSWidth(self.bounds) height:NSHeight(self.bounds)];
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)renderView
{
	[[self openGLContext] makeCurrentContext];
	
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	[renderer render];
	
	CGLFlushDrawable([[self openGLContext] CGLContextObj]);
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)dealloc
{
	CVDisplayLinkStop(displayLink);
	CVDisplayLinkRelease(displayLink);
	
	renderer = nil;
	
	//[super dealloc]; //ARC!
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint curloc;
	NSPoint preloc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	//NSLog(@"mouseDown:(%@)", NSStringFromPoint(loc));
	
	BOOL isInside;
	BOOL isDragged = NO;
	BOOL keepOn = YES;
	
	while(keepOn) {
		theEvent = [[self window] nextEventMatchingMask:NSLeftMouseDraggedMask | NSLeftMouseUpMask];
		
		curloc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		isInside = [self mouse:curloc inRect:[self bounds]];
		
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
				//NSLog(@"mouse dragged:(%@)", NSStringFromPoint(curloc));
				[renderer cameraTrackWithMouseDeltaX:(curloc.x - preloc.x) deltaY:(curloc.y - preloc.y)];
				isDragged = YES;
				break;
			case NSLeftMouseUp:
				//NSLog(@"mouse up:(%@)", NSStringFromPoint(curloc));
				if(!isDragged) {
					// OSXは左下原点なのでそのまま
					[renderer pickupAtScreenPointX:curloc.x y:curloc.y];
				}
				keepOn = NO;
				break;
			default:
				break;
		}
		
		preloc = curloc;
	}
}

/*
- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint loc = [theEvent locationInWindow];
	NSLog(@"mouseDragged:(%@)", NSStringFromPoint(loc));
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint loc = [theEvent locationInWindow];
	NSLog(@"mouseUp:(%@)", NSStringFromPoint(loc));
}
*/

- (void)rearrangeObjects
{
	[renderer arrangeObjects];
}

@end

//
//  GKPViewController.m
//  GLKitPickTestiOS
//
//  Created by Satoru NAKAJIMA on 2013/03/07.
//  Copyright (c) 2013年 Satoru NAKAJIMA. All rights reserved.
//

#import "GKPViewController.h"
#import "GKPRenderer.h"

@interface GKPViewController ()
{
	GKPRenderer *renderer;
	BOOL touchMoved;
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation GKPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
	renderer = [[GKPRenderer alloc] init];
	/*
	CGRect apprect = [UIScreen mainScreen].applicationFrame;
	[renderer resizeWithWidth:CGRectGetWidth(apprect) height:CGRectGetHeight(apprect)];
	 */
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    renderer = nil;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
	
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	//NSLog(NSStringFromCGRect(rect));
    [renderer render];
}

- (void)viewDidLayoutSubviews
{
	CGRect viewrect = CGRectApplyAffineTransform(self.view.frame, self.view.transform);
	[renderer resizeWithWidth:viewrect.size.width height:viewrect.size.height];
}

// events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	touchMoved = NO;
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *atouch = [touches anyObject];
	CGPoint curloc = [atouch locationInView:self.view];
	CGPoint preloc = [atouch previousLocationInView:self.view];
	
	// iOSは左上原点なのでyを反転
	[renderer cameraTrackWithMouseDeltaX:curloc.x - preloc.x deltaY:-(curloc.y - preloc.y)];
	
	touchMoved = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *atouch = [touches anyObject];
	CGPoint curloc = [atouch locationInView:self.view];
	//CGPoint preloc = [atouch previousLocationInView:self.view];
	
	if(!touchMoved) {
		if(atouch.tapCount < 2) {
			// iOSは左上原点なのでyを反転
			[renderer pickupAtScreenPointX:curloc.x y:renderer.viewportHeight - curloc.y];
		}
		else {
			// ダブルタップは並べ替えにする
			[renderer arrangeObjects];
		}
	}
	//NSLog(@"cur:%@, pre:%@", NSStringFromCGPoint(curloc), NSStringFromCGPoint(preloc));
}

/*
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}
*/
@end

//
//  GKPRenderer.h
//  GLKitPickTest
//
//  Created by Satoru NAKAJIMA on 2013/03/05.
//  Copyright (c) 2013年 Satoru NAKAJIMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GKPRenderer : NSObject
{
	GLKBaseEffect *effect;
	
	GLKMatrix4 projectionMatrix;
	
	
	GLKVector2 cameraRot;
	GLKVector3 cameraPosition;
	GLKVector3 cameraLookat;
	float cameraDistance;
	GLKMatrix4 cameraMatrix;
	
	NSMutableArray *geometries;
	NSMutableArray *objects;
	
	NSMutableArray *selectedObjs;
	
	NSTimeInterval startTime;
}

@property (nonatomic) int viewportWidth;
@property (nonatomic) int viewportHeight;

- (void)resizeWithWidth:(int)nw height:(int)nh;
- (void)render;
- (void)initScene;
- (void)arrangeObjects;

- (void)cameraTrackWithMouseDeltaX:(float)dx deltaY:(float)dy;
- (void)pickupAtScreenPointX:(float)px y:(float)py;
@end

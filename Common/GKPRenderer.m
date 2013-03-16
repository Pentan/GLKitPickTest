//
//  GKPRenderer.m
//  GLKitPickTest
//
//  Created by Satoru NAKAJIMA on 2013/03/05.
//  Copyright (c) 2013年 Satoru NAKAJIMA. All rights reserved.
//

#import "glinclude.h"
#import <GLKit/GLKit.h>

#import "GKPRenderer.h"
#import "GKP3DObject.h"

/////
#define OBJECTS_NUM		16
#define FRAND()			((rand() & 0xffff)/65536.0f)

#define CAMERA_DISTANCE		6.0f

enum {
	SELECTED_COLOR0,
	SELECTED_COLOR1,
	SELECTED_COLOR2,
	SELECTED_COLOR3,
	SELECTED_COLOR4,
	SELECTED_COLORN,
	SELECTED_COLOR_NUM
};


static GLKVector4 normalColor = {{0.8f, 0.8f, 0.8f, 1.0f}};
static GLKVector4 selectedColors[SELECTED_COLOR_NUM] = {
	{{1.0f, 0.2f, 0.2f, 1.0f}},
	{{0.2f, 1.0f, 0.2f, 1.0f}},
	{{0.2f, 0.2f, 1.0f, 1.0f}},
	{{1.0f, 0.2f, 1.0f, 1.0f}},
	{{0.2f, 1.0f, 1.0f, 1.0f}},
	{{1.0f, 1.0f, 0.2f, 1.0f}}
};

/////
@interface GKPRenderer ()
- (void)updateProjectionMatrix;
- (void)updateCameraMatrix;
@end

@implementation GKPRenderer

- (id)init
{
	if((self = [super init])) {
		
		effect = [[GLKBaseEffect alloc] init];
		effect.light0.enabled = GL_TRUE;
		effect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
		effect.light0.position = GLKVector4Normalize(GLKVector4Make(0.2, 0.2, 1.0, 0.0));
		
		[self initScene];
		
		selectedObjs = [[NSMutableArray alloc] initWithCapacity:SELECTED_COLOR_NUM * 2];
		
		startTime = [NSDate timeIntervalSinceReferenceDate];
		
		return self;
	}
	return nil;
}

- (void)dealloc
{
	effect = nil;
	geometries = nil;
	objects = nil;
	selectedObjs = nil;
}

- (void)resizeWithWidth:(int)nw height:(int)nh
{
	_viewportWidth = nw;
	_viewportHeight = nh;
	
	glViewport(0, 0, _viewportWidth, _viewportHeight);
	
	[self updateProjectionMatrix];
}

- (void)render
{
	
	//NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
	//NSTimeInterval elapsedTime = currentTime - startTime;
	
	glClearColor(1.0f, 1.0f, 0.8f, 0.0f);
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_CULL_FACE);
	
	// projection
	effect.transform.projectionMatrix = projectionMatrix;
	
	// objects
	for(GKP3DObject *obj in objects) {
		GLKMatrix4 tm = [obj calcTransform];
		
		effect.transform.modelviewMatrix = GLKMatrix4Multiply(cameraMatrix, tm);
		effect.material.diffuseColor = obj.color;
		
		[obj.geometry bindVertexArray];
		[effect prepareToDraw];
		[obj.geometry draw];
	}
	
	glBindVertexArray(0);
	
	glFinish();
}

/////
- (void)initScene
{
	// objects
	geometries = [[NSMutableArray alloc] initWithCapacity:2];
	[geometries addObject:[[GKPCubeGeometry alloc] initWithWidth:1.0f height:1.0f depth:1.0f]];
	[geometries addObject:[[GKPSphereGeometry alloc] initWithRadius:0.5 holizontalSegments:16 verticalSegments:8]];
	
	objects = [[NSMutableArray alloc] initWithCapacity:OBJECTS_NUM];
	
	for(int i = 0; i < OBJECTS_NUM; i++) {
		GKP3DObject *obj = [[GKP3DObject alloc] init];
		[objects addObject:obj];
	}
	srand((unsigned int)time(NULL));
	[self arrangeObjects];
	
	// camera
	cameraLookat = GLKVector3Make(0.0f, 0.0f, 0.0f);
	cameraRot = GLKVector2Make(0.0f, 0.0f);
	cameraDistance = CAMERA_DISTANCE;
	[self updateCameraMatrix];
}

- (void)arrangeObjects
{
	[selectedObjs removeAllObjects];
	
	for(GKP3DObject *obj in objects) {
		GKP3DGeometry *geom = [geometries objectAtIndex:rand() % [geometries count]];
		
		obj.geometry = geom;
		obj.color = normalColor;
		
		[obj setTranslationWithX:(FRAND() - 0.5f) * 5.0f
							   y:(FRAND() - 0.5f) * 5.0f
							   z:(FRAND() - 0.5f) * 5.0f];
		[obj setEulerRotationWithX:FRAND() * M_PI
								 y:FRAND() * M_PI
								 z:FRAND() * M_PI];
		[obj setScaleWithX:(FRAND() * 1.0f + 0.5f)
						 y:(FRAND() * 1.0f + 0.5f)
						 z:(FRAND() * 1.0f + 0.5f)];
		
		//printf("[%d](%.4f,%.4f,%.4f)\n", i, obj.translation.x, obj.translation.y, obj.translation.z);
	}
}

- (void)updateProjectionMatrix
{
	float fov = 60.0f * M_PI / 180.0f;
	float aspect = (float)_viewportWidth / (float)_viewportHeight;
	projectionMatrix = GLKMatrix4MakePerspective(fov, aspect, 0.1f, 100.0f);
}

- (void)updateCameraMatrix
{
	cameraPosition.x = sinf(cameraRot.y) * cosf(cameraRot.x) * cameraDistance;
	cameraPosition.y = sinf(cameraRot.x) * cameraDistance;
	cameraPosition.z = cosf(cameraRot.y) * cosf(cameraRot.x) * cameraDistance;
	cameraMatrix = GLKMatrix4MakeLookAt(cameraPosition.x, cameraPosition.y, cameraPosition.z,
										cameraLookat.x, cameraLookat.y, cameraLookat.z,
										0.0f, 1.0f, 0.0f);
}

- (void)cameraTrackWithMouseDeltaX:(float)dx deltaY:(float)dy
{
	//引数は左下原点の座標
	cameraRot.y -= dx / _viewportWidth * M_PI * 2.0f;
	cameraRot.x -= dy / _viewportHeight * M_PI;
	if(fabs(cameraRot.x) >= M_PI * 0.4999f) {
		cameraRot.x = M_PI * 0.4999f * ((cameraRot.x > 0.0)? 1.0f:-1.0f);
	}
	
	[self updateCameraMatrix];
}

- (void)pickupAtScreenPointX:(float)px y:(float)py;
{
	//引数は左下原点の座標
	bool isSuccess;
#if 1
	// 人力 unproject
	/* // wで割らずにGLKMatrix4MultiplyAndProjectVector3を使えば良いじゃない
	GLKVector4 screenVec = GLKVector4Make((px / _viewportWidth) * 2.0f - 1.0f, (py / _viewportHeight) * 2.0f - 1.0f, 1.0f, 1.0f);
	GLKMatrix4 ivm = GLKMatrix4Invert(GLKMatrix4Multiply(projectionMatrix, cameraMatrix), &isSuccess);
	GLKVector4 upv4 = GLKMatrix4MultiplyVector4(ivm, screenVec);
	GLKVector3 upv = GLKVector3MultiplyScalar(GLKVector3MakeWithArray(upv4.v), 1.0f / upv4.w);
	*/
	GLKVector3 screenVec = GLKVector3Make((px / _viewportWidth) * 2.0f - 1.0f, (py / _viewportHeight) * 2.0f - 1.0f, 1.0f);
	GLKMatrix4 ivm = GLKMatrix4Invert(GLKMatrix4Multiply(projectionMatrix, cameraMatrix), &isSuccess);
	GLKVector3 upv = GLKMatrix4MultiplyAndProjectVector3(ivm, screenVec);
#else
	// GLKit unproject
	GLKVector3 screenVec = GLKVector3Make(px, py, 1.0f);
	int vp[] = {0, 0, _viewportWidth, _viewportHeight};
	GLKVector3 upv = GLKMathUnproject(screenVec, cameraMatrix, projectionMatrix, vp, &isSuccess);
#endif
	
	assert(isSuccess);
	if(!isSuccess) {
		return;
	}
	
	GLKVector3 rayorg = cameraPosition;
	GLKVector3 raydir = GLKVector3Normalize(GLKVector3Subtract(upv, cameraPosition));
	
	for(GKP3DObject *selobj in selectedObjs) {
		selobj.color = normalColor;
	}
	[selectedObjs removeAllObjects];
	
	for(GKP3DObject *obj in objects) {
		GLKVector3 hitp;
		if([obj intersectWithRayOrigin:rayorg direction:raydir hitPosition:&hitp]) {
			obj.hitPosition = hitp;
			obj.hitDistance = GLKVector3Distance(rayorg, hitp);
			
			//NSLog(@"hit %p at %@(to %.4f)", obj, NSStringFromGLKVector3(hitp), obj.hitDistance);
			[selectedObjs addObject:obj];
		}
	}
	
	// ソートしてみる
	[selectedObjs sortUsingComparator:^NSComparisonResult(GKP3DObject *o1, GKP3DObject *o2){
		if(o1.hitDistance == o2.hitDistance) {
			return (NSComparisonResult)NSOrderedSame;
		}
		return (NSComparisonResult)((o1.hitDistance - o2.hitDistance > 0.0f)? NSOrderedDescending : NSOrderedAscending);
	}];
	
	//NSLog(@"hit %ld objects", [selectedObjs count]);
	int colid = SELECTED_COLOR0;
	for(GKP3DObject *selobj in selectedObjs) {
		//NSLog(@"hit %p object: %f", selobj, selobj.hitDistance);
		selobj.color = selectedColors[colid];
		if(++colid > SELECTED_COLORN) {
			colid = SELECTED_COLORN;
		}
	}
}

@end

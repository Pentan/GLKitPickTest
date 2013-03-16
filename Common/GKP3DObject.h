//
//  GKP3DObject.h
//  GLKitPickTest
//
//  Created by Satoru NAKAJIMA on 2013/03/05.
//  Copyright (c) 2013年 Satoru NAKAJIMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "glinclude.h"
#import <GLKit/GLKit.h>

typedef struct _GKPVertex GKPVertex;

@interface GKP3DGeometry : NSObject
{
	GKPVertex *vertexData;
	GLsizei vertexDataLength;
	GLuint *indices;
	GLsizei indicesLength;
}
@property (readonly) GLuint vertexArray;
@property (readonly) GLuint vertexBuffer;
@property (readonly) GLuint elementsBuffer;
- (void)bindVertexArray;
- (void)draw;
- (BOOL)intersectWithRayOrigin:(GLKVector3)rayorg direction:(GLKVector3)raydir hitPosition:(GLKVector3*)ovec;
@end

@interface GKPCubeGeometry : GKP3DGeometry
- (id)initWithWidth:(GLfloat)w height:(GLfloat)h depth:(GLfloat)d;
@end

@interface GKPSphereGeometry : GKP3DGeometry
- (id)initWithRadius:(GLfloat)r holizontalSegments:(int)hseg verticalSegments:(int)vseg;
@end


@interface GKP3DObject : NSObject
{
	//GLKBaseEffect *effect;
}
@property (strong, nonatomic) GKP3DGeometry *geometry;
@property (nonatomic) GLKVector4 color;
@property (nonatomic) GLKVector3 translation;
@property (nonatomic) GLKVector3 eulerRotation;
@property (nonatomic) GLKVector3 scale;
@property (nonatomic) GLKMatrix4 transformMatrix; // holds last result of calcTransform.

@property (nonatomic) GLKVector3 hitPosition;
@property (nonatomic) float hitDistance;

- (void)setTranslationWithX:(GLfloat)tx y:(GLfloat)ty z:(GLfloat)tz;
- (void)setEulerRotationWithX:(GLfloat)rx y:(GLfloat)ry z:(GLfloat)rz;
- (void)setScaleWithX:(GLfloat)sx y:(GLfloat)sy z:(GLfloat)sz;
- (GLKMatrix4)calcTransform;
- (BOOL)intersectWithRayOrigin:(GLKVector3)rayorg direction:(GLKVector3)raydir hitPosition:(GLKVector3*)ovec;
@end

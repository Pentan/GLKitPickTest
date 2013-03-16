//
//  GKP3DObject.m
//  GLKitPickTest
//
//  Created by Satoru NAKAJIMA on 2013/03/05.
//  Copyright (c) 2013年 Satoru NAKAJIMA. All rights reserved.
//

#import "GKP3DObject.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

struct _GKPVertex {
	GLKVector3 position;
	GLKVector3 normal;
	//GLKVector4 color;
};

@interface GKP3DGeometry ()
- (void)allocVertexData:(GLsizei)s;
- (void)allocIndiceData:(GLsizei)s;
- (void)setupVertexArray;
@end

@implementation GKP3DGeometry
- (id)init
{
	if((self = [super init])) {
		vertexData = NULL;
		vertexDataLength = 0;
		indices = NULL;
		indicesLength = 0;
		_vertexArray = 0;
		_vertexBuffer = 0;
		_elementsBuffer = 0;
		return self;
	}
	return nil;
}

- (void)dealloc
{
	GLuint bufs[2] = {_vertexBuffer, _elementsBuffer};
	glDeleteBuffers(2, bufs);
	
	if(_vertexArray) {
		glDeleteVertexArrays(1, &_vertexArray);
	}
	if(vertexData) {
		free(vertexData);
		vertexDataLength = 0;
	}
	if(indices) {
		free(indices);
		indicesLength = 0;
	}
}

- (void)bindVertexArray
{
	glBindVertexArray(_vertexArray);
}

- (void)draw
{
	assert(!indices || indicesLength > 0);
	glDrawElements(GL_TRIANGLES, indicesLength, GL_UNSIGNED_INT, 0);
}

- (BOOL)intersectWithRayOrigin:(GLKVector3)rayorg direction:(GLKVector3)raydir hitPosition:(GLKVector3*)ovec
{
	BOOL ishit = NO;
	float hitt = FLT_MAX;
	GLKVector3 hitp;
	
	// 単純に三角総当たり
	for(int i = 0; i < indicesLength; i+=3) {
		GLKVector3 v0 = vertexData[indices[i]].position;
		GLKVector3 v1 = vertexData[indices[i + 1]].position;
		GLKVector3 v2 = vertexData[indices[i + 2]].position;
		GLKVector3 v10 = GLKVector3Subtract(v1, v0);
		GLKVector3 v20 = GLKVector3Subtract(v2, v0);
		GLKVector3 facen = GLKVector3Normalize(GLKVector3CrossProduct(v10, v20));
		
		float dotnd = GLKVector3DotProduct(facen, raydir);
		if(fabs(dotnd) < 1e-20f) { // レイと面が平行
			continue;
		}
		
		GLKVector3 v0r = GLKVector3Subtract(v0, rayorg);
		float dotno = GLKVector3DotProduct(facen, v0r);
		float t = dotno / dotnd;
		
		if(t < 0.0f) { // レイより後ろ
			continue;
		}
		
		// 三角の平面上の点
		GLKVector3 hp = GLKVector3Add(rayorg, GLKVector3MultiplyScalar(raydir, t));
		
		// Three.jsが使ってたのをまねっこ
		// http://www.blackpawn.com/texts/pointinpoly/default.html
		GLKVector3 vp0 = GLKVector3Subtract(hp, v0);
		
		float dot00 = GLKVector3DotProduct(v20, v20);
		float dot01 = GLKVector3DotProduct(v20, v10);
		float dot02 = GLKVector3DotProduct(v20, vp0);
		float dot11 = GLKVector3DotProduct(v10, v10);
		float dot12 = GLKVector3DotProduct(v10, vp0);
		
		float invDenom = 1.0f / ( dot00 * dot11 - dot01 * dot01 );
		float u = ( dot11 * dot02 - dot01 * dot12 ) * invDenom;
		float v = ( dot00 * dot12 - dot01 * dot02 ) * invDenom;
		
		if((u >= 0.0f) && (v >= 0.0f) && (u + v < 1.0f)) {
			//最も手前にある点を選ぶ
			if(t < hitt) {
				hitt = t;
				hitp = hp;
				ishit = YES;
			}
		}
	}
	
	if(ovec != NULL) {
		*ovec = hitp;
	}
	
	return ishit;
}

// protected methods
- (void)allocVertexData:(GLsizei)s
{
	vertexData = calloc(sizeof(GKPVertex), s);
	if(vertexData) {
		vertexDataLength = s;
	}
}

- (void)allocIndiceData:(GLsizei)s
{
	indices = calloc(sizeof(GLuint), s);
	if(indices) {
		indicesLength = s;
	}
}

- (void)setupVertexArray {
	assert(_vertexBuffer == 0 || _vertexArray == 0 || !vertexData);
	if(_vertexBuffer || _vertexArray || !vertexData) {
		return;
	}
	
	glGenVertexArrays(1, &_vertexArray);
	glBindVertexArray(_vertexArray);
	
	GLuint bufs[2];
	glGenBuffers(2, bufs);
	_vertexBuffer = bufs[0];
	_elementsBuffer = bufs[1];
	
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(GKPVertex) * vertexDataLength, vertexData, GL_STATIC_DRAW);
	glEnableVertexAttribArray(GLKVertexAttribPosition);
	glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GKPVertex), BUFFER_OFFSET(offsetof(GKPVertex, position)));
	glEnableVertexAttribArray(GLKVertexAttribNormal);
	glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(GKPVertex), BUFFER_OFFSET(offsetof(GKPVertex, normal)));
	//glEnableVertexAttribArray(GLKVertexAttribColor);
	//glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(GKPVertex), BUFFER_OFFSET(offsetof(GKPVertex, color)));
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _elementsBuffer);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * indicesLength, indices, GL_STATIC_DRAW);
	
	glBindVertexArray(0);
}
@end

@implementation GKPCubeGeometry
- (id)initWithWidth:(GLfloat)w height:(GLfloat)h depth:(GLfloat)d
{
	if((self = [super init])) {
		int i;
		
		// vertices
		[self allocVertexData:6 * 4];
		
		w *= 0.5f;
		h *= 0.5f;
		d *= 0.5f;
		
		// front
		vertexData[0].position = GLKVector3Make(-w,  h, d);
		vertexData[0].normal =GLKVector3Make(0.0f, 0.0f, 1.0f);
		vertexData[1].position = GLKVector3Make(-w, -h, d);
		vertexData[1].normal =GLKVector3Make(0.0f, 0.0f, 1.0f);
		vertexData[2].position = GLKVector3Make( w, -h, d);
		vertexData[2].normal =GLKVector3Make(0.0f, 0.0f, 1.0f);
		vertexData[3].position = GLKVector3Make( w,  h, d);
		vertexData[3].normal =GLKVector3Make(0.0f, 0.0f, 1.0f);
		
		// back
		vertexData[4].position = GLKVector3Make( w,  h, -d);
		vertexData[4].normal =GLKVector3Make(0.0f, 0.0f, -1.0f);
		vertexData[5].position = GLKVector3Make( w, -h, -d);
		vertexData[5].normal =GLKVector3Make(0.0f, 0.0f, -1.0f);
		vertexData[6].position = GLKVector3Make(-w, -h, -d);
		vertexData[6].normal =GLKVector3Make(0.0f, 0.0f, -1.0f);
		vertexData[7].position = GLKVector3Make(-w,  h, -d);
		vertexData[7].normal =GLKVector3Make(0.0f, 0.0f, -1.0f);
		
		// left
		vertexData[ 8].position = GLKVector3Make(w,  h,  d);
		vertexData[ 8].normal =GLKVector3Make(1.0f, 0.0f, 0.0f);
		vertexData[ 9].position = GLKVector3Make(w, -h,  d);
		vertexData[ 9].normal =GLKVector3Make(1.0f, 0.0f, 0.0f);
		vertexData[10].position = GLKVector3Make(w, -h, -d);
		vertexData[10].normal =GLKVector3Make(1.0f, 0.0f, 0.0f);
		vertexData[11].position = GLKVector3Make(w,  h, -d);
		vertexData[11].normal =GLKVector3Make(1.0f, 0.0f, 0.0f);
		
		// right
		vertexData[12].position = GLKVector3Make(-w,  h, -d);
		vertexData[12].normal =GLKVector3Make(-1.0f, 0.0f, 0.0f);
		vertexData[13].position = GLKVector3Make(-w, -h, -d);
		vertexData[13].normal =GLKVector3Make(-1.0f, 0.0f, 0.0f);
		vertexData[14].position = GLKVector3Make(-w, -h,  d);
		vertexData[14].normal =GLKVector3Make(-1.0f, 0.0f, 0.0f);
		vertexData[15].position = GLKVector3Make(-w,  h,  d);
		vertexData[15].normal =GLKVector3Make(-1.0f, 0.0f, 0.0f);
		
		// top
		vertexData[16].position = GLKVector3Make(-w, h, -d);
		vertexData[16].normal =GLKVector3Make(0.0f, 1.0f, 0.0f);
		vertexData[17].position = GLKVector3Make(-w, h,  d);
		vertexData[17].normal =GLKVector3Make(0.0f, 1.0f, 0.0f);
		vertexData[18].position = GLKVector3Make( w, h,  d);
		vertexData[18].normal =GLKVector3Make(0.0f, 1.0f, 0.0f);
		vertexData[19].position = GLKVector3Make( w, h, -d);
		vertexData[19].normal =GLKVector3Make(0.0f, 1.0f, 0.0f);
		
		// bottom
		vertexData[20].position = GLKVector3Make( w, -h, -d);
		vertexData[20].normal =GLKVector3Make(0.0f, -1.0f, 0.0f);
		vertexData[21].position = GLKVector3Make( w, -h,  d);
		vertexData[21].normal =GLKVector3Make(0.0f, -1.0f, 0.0f);
		vertexData[22].position = GLKVector3Make(-w, -h,  d);
		vertexData[22].normal =GLKVector3Make(0.0f, -1.0f, 0.0f);
		vertexData[23].position = GLKVector3Make(-w, -h, -d);
		vertexData[23].normal =GLKVector3Make(0.0f, -1.0f, 0.0f);
		
		// faces
		[self allocIndiceData:6 * 2 * 3];
		GLuint *indptr = indices;
		for(i = 0; i < 6; i++) {
			int vstart = i * 4;
			indptr[0] = vstart;
			indptr[1] = vstart + 1;
			indptr[2] = vstart + 2;
			
			indptr[3] = vstart + 2;
			indptr[4] = vstart + 3;
			indptr[5] = vstart;
			
			indptr += 6;
		}
		
		[self setupVertexArray];
		
		return self;
	}
	return nil;
}
@end

@implementation GKPSphereGeometry
- (id)initWithRadius:(GLfloat)r holizontalSegments:(int)hseg verticalSegments:(int)vseg
{
	if((self = [super init])) {
		
		// vertices
		[self allocVertexData:2 + hseg * (vseg - 1)];
		GKPVertex *vdatptr = vertexData;
		
		// first, top pole
		vdatptr->position = GLKVector3Make(0.0f, r, 0.0f);
		vdatptr->normal = GLKVector3Make(0.0f, 1.0f, 0.0f);
		vdatptr++;
		
		// body. top to bottom and x-z CCW
		for(int iv = 1; iv < vseg; iv++) {
			float vsn = sin((iv * M_PI) / vseg);
			float vcs = cos((iv * M_PI) / vseg);
			for(int ih = 0; ih < hseg; ih++) {
				float hsn = sin((ih * M_PI * 2.0) / hseg);
				float hcs = cos((ih * M_PI * 2.0) / hseg);
				
				vdatptr->position = GLKVector3Make(hsn * vsn * r, vcs * r, hcs * vsn * r);
				vdatptr->normal = GLKVector3Make(hsn * vsn, vcs, hcs * vsn);
				vdatptr++;
			}
		}
		
		// last, bottom pole
		vdatptr->position = GLKVector3Make(0.0f, -r, 0.0f);
		vdatptr->normal = GLKVector3Make(0.0f, -1.0f, 0.0f);
		
		
		// faces
		[self allocIndiceData:((hseg * 2) + hseg * (vseg - 2) * 2) * 3]; //((top and bottom fan) + (body strips)) * 3
		GLuint *indptr = indices;
		
		// top fan
		int istart = 1;
		for(int i = 0; i < hseg; i++) {
			indptr[0] = 0;
			indptr[1] = istart + i;
			indptr[2] = istart + (i + 1) % hseg;
			indptr += 3;
		}
		
		// body
		for(int iv = 0; iv < vseg - 2; iv++) {
			int topstart = iv * hseg + 1;
			int btmstart = (iv + 1) * hseg + 1;
			for(int ih = 0; ih < hseg; ih++) {
				indptr[0] = topstart + ih;
				indptr[1] = btmstart + ih;
				indptr[2] = btmstart + (ih + 1) % hseg;
				
				indptr[3] = btmstart + (ih + 1) % hseg;
				indptr[4] = topstart + (ih + 1) % hseg;
				indptr[5] = topstart + ih;
				
				indptr += 6;
			}
		}
		
		// bottom fan
		istart = (vertexDataLength - 1) - hseg;
		for(int i = 0; i < hseg; i++) {
			indptr[0] = vertexDataLength - 1;
			indptr[1] = istart + (i + 1) % hseg;
			indptr[2] = istart + i;
			indptr += 3;
		}
		
		[self setupVertexArray];
		
		return self;
	}
	return nil;
}
@end


@implementation GKP3DObject

- (id)init
{
	if((self = [super init])) {
		_geometry = nil;
		_color = GLKVector4Make(0.8f, 0.8f, 0.8f, 1.0f);
		_translation = GLKVector3Make(0.0f, 0.0f, 0.0f);
		_eulerRotation = GLKVector3Make(0.0f, 0.0f, 0.0f);
		_scale = GLKVector3Make(1.0f, 1.0f, 1.0f);
		_transformMatrix = GLKMatrix4Identity;
		
		return self;
	}
	return nil;
}

- (void)setTranslationWithX:(GLfloat)tx y:(GLfloat)ty z:(GLfloat)tz
{
	_translation = GLKVector3Make(tx, ty, tz);
}

- (void)setEulerRotationWithX:(GLfloat)rx y:(GLfloat)ry z:(GLfloat)rz
{
	_eulerRotation = GLKVector3Make(rx, ry, rz);
}

- (void)setScaleWithX:(GLfloat)sx y:(GLfloat)sy z:(GLfloat)sz
{
	_scale = GLKVector3Make(sx, sy, sz);
}

- (GLKMatrix4)calcTransform
{
	GLKMatrix4 m;
	m = GLKMatrix4MakeTranslation(_translation.x, _translation.y, _translation.z);
	m = GLKMatrix4RotateX(m, _eulerRotation.x);
	m = GLKMatrix4RotateY(m, _eulerRotation.y);
	m = GLKMatrix4RotateZ(m, _eulerRotation.z);
	m = GLKMatrix4Scale(m, _scale.x, _scale.y, _scale.z);
	_transformMatrix = m;
	return m;
}

- (BOOL)intersectWithRayOrigin:(GLKVector3)rayorg direction:(GLKVector3)raydir hitPosition:(GLKVector3*)ovec
{
	// using current transform
	bool isinv;
	GLKMatrix4 itm = GLKMatrix4Invert(_transformMatrix, &isinv);
	
	assert(isinv);
	if(!isinv) {
		return NO;
	}
	
	rayorg = GLKMatrix4MultiplyVector3WithTranslation(itm, rayorg);
	raydir = GLKMatrix4MultiplyVector3(itm, raydir);
	raydir = GLKVector3Normalize(raydir);
	
	BOOL ret = [_geometry intersectWithRayOrigin:rayorg direction:raydir hitPosition:ovec];
	
	if(ovec) {
		*ovec = GLKMatrix4MultiplyVector3WithTranslation(_transformMatrix, *ovec);
	}
	
	return ret;
}

@end


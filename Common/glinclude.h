//
//  glinclude.h
//  GLKitPickTestiOS
//
//  Created by Satoru NAKAJIMA on 2013/03/07.
//  Copyright (c) 2013年 Satoru NAKAJIMA. All rights reserved.
//

#ifndef GLKitPickTestiOS_glinclude_h
#define GLKitPickTestiOS_glinclude_h

#if TARGET_OS_IPHONE

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define glBindVertexArray glBindVertexArrayOES
#define glGenVertexArrays glGenVertexArraysOES
#define glDeleteVertexArrays glDeleteVertexArraysOES

#else

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

#endif

#endif

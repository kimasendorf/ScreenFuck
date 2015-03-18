 /*
 
 File: ScreenFuck.h
 
 Copyright (C) 2010 ASDF. All Rights Reserved.
 
 */ 
 
#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@interface ScreenFuck : NSObject {
	NSOpenGLContext *mGLContext;
    void *mData;
    long mByteWidth, mWidth, mHeight;
}

- (void) readPartialScreenToBuffer:(size_t)width bufferHeight:(size_t)height bufferBaseAddress:(void *)baseAddress posX:(long)x posY:(long)y safeOrRisky:(int)sr;
- (void) readFullScreenToBuffer:(int)sr;
- (void) manipulateBuffer:(int)sr;
- (void) createTIFFImageFileOnDesktop;


@end

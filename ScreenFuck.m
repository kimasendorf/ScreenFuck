 /*
 
 File: ScreenFuck.m
 
 Copyright (C) 2010 ASDF. All Rights Reserved.
 
 */ 
 
#import "ScreenFuck.h"

@interface ScreenFuck (PrivateMethods)
	-(void)flipImageData;
	-(CGImageRef)createRGBImageFromBufferData;
@end

@implementation ScreenFuck (PrivateMethods)
  
-(void)flipImageData
{
    long top, bottom;
    void * buffer;
    void * topP;
    void * bottomP;
    void * base;
    long rowBytes;

    top = 0;
    bottom = mHeight - 1;
    base = mData;
    rowBytes = mByteWidth;
    buffer = malloc(rowBytes);
    NSAssert( buffer != nil, @"malloc failure");

    while ( top < bottom )
    {
        topP = (void *)((top * rowBytes) + (intptr_t)base);
        bottomP = (void *)((bottom * rowBytes) + (intptr_t)base);

        bcopy( topP, buffer, rowBytes );
        bcopy( bottomP, topP, rowBytes );
        bcopy( buffer, bottomP, rowBytes );

        ++top;
        --bottom;
    }
    free( buffer );
}

// Create a RGB CGImageRef from our buffer data
-(CGImageRef)createRGBImageFromBufferData
{
    CGColorSpaceRef cSpace = CGColorSpaceCreateWithName (kCGColorSpaceGenericRGB);
    NSAssert( cSpace != NULL, @"CGColorSpaceCreateWithName failure");

    CGContextRef bitmap = CGBitmapContextCreate(mData, mWidth, mHeight, 8, mByteWidth,
                                    cSpace,  
	#if __BIG_ENDIAN__
		kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big /* XRGB Big Endian */);
	#else
		kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little /* XRGB Little Endian */);
	#endif                                    
    NSAssert( bitmap != NULL, @"CGBitmapContextCreate failure");

    // Get rid of color space
    CFRelease(cSpace);

    // Make an image out of our bitmap; does a cheap vm_copy of the  
    // bitmap
    CGImageRef image = CGBitmapContextCreateImage(bitmap);
    NSAssert( image != NULL, @"CGBitmapContextCreate failure");

    // Get rid of bitmap
    CFRelease(bitmap);
    
    return image;
}

@end

@implementation ScreenFuck

#pragma mark ---------- Initialization ----------

-(id)init
{
    if (self = [super init])
    {
		// Create a full-screen OpenGL graphics context
		
		// Specify attributes of the GL graphics context
		NSOpenGLPixelFormatAttribute attributes[] = {
			NSOpenGLPFAFullScreen,
			NSOpenGLPFAScreenMask,
			CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
			(NSOpenGLPixelFormatAttribute) 0
			};

		NSOpenGLPixelFormat *glPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
		if (!glPixelFormat)
		{
			return nil;
		}

		// Create OpenGL context used to render
		mGLContext = [[[NSOpenGLContext alloc] initWithFormat:glPixelFormat shareContext:nil] autorelease];

		// Cleanup, pixel format object no longer needed
		[glPixelFormat release];
    
        if (!mGLContext)
        {
            [self release];
            return nil;
        }
        [mGLContext retain];

        // Set our context as the current OpenGL context
        [mGLContext makeCurrentContext];
        // Set full-screen mode
        [mGLContext setFullScreen];

		NSRect mainScreenRect = [[NSScreen mainScreen] frame];
		mWidth = mainScreenRect.size.width;
		mHeight = mainScreenRect.size.height;

        mByteWidth = mWidth * 4;                // Assume 4 bytes/pixel for now
        mByteWidth = (mByteWidth + 3) & ~3;    // Align to 4 bytes

        mData = malloc(mByteWidth * mHeight);
        NSAssert( mData != 0, @"malloc failed");
		
    }
    return self;
}

#pragma mark ---------- Screen Reader  ----------

-(void)readFullScreenToBuffer:(int)sr
{
    [self readPartialScreenToBuffer:mWidth bufferHeight:mHeight bufferBaseAddress:mData posX:0 posY:0 safeOrRisky:sr];
}

// Use this routine if you want to read only a portion of the screen pixels
-(void)readPartialScreenToBuffer:(size_t)width bufferHeight:(size_t)height bufferBaseAddress:(void *)baseAddress posX:(long)x posY:(long)y safeOrRisky:(int)sr
{
    // select front buffer as our source for pixel data
    glReadBuffer(GL_FRONT);
    
    //Read OpenGL context pixels directly.

    // For extra safety, save & restore OpenGL states that are changed
    glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4); /* Force 4-byte alignment */
    glPixelStorei(GL_PACK_ROW_LENGTH, 0);
    glPixelStorei(GL_PACK_SKIP_ROWS, 0);
    glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
    
	
    //Read a block of pixels from the frame buffer
	long modes = 10;
	
	if (sr == 0) {
		modes = 8;
	}
	
	long bitMode = arc4random() % modes;
	
	//NSLog(@"mode: %d", bitMode);
	
	switch (bitMode) {
		case 0:
			glReadPixels(x, y, width, height, GL_BGRA, GL_UNSIGNED_SHORT_4_4_4_4, baseAddress);
			break;
		case 1:
			glReadPixels(x, y, width, height, GL_BGRA, GL_UNSIGNED_SHORT_4_4_4_4_REV, baseAddress);
			break;
		case 2:
			glReadPixels(x, y, width, height, GL_BGRA, GL_UNSIGNED_SHORT_5_5_5_1, baseAddress);
			break;
		case 3:
			glReadPixels(x, y, width, height, GL_BGRA, GL_UNSIGNED_SHORT_1_5_5_5_REV, baseAddress);
			break;
		case 4:
			glReadPixels(x, y, width, height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, baseAddress);
			break;
		case 5:
			glReadPixels(x, y, width, height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, baseAddress);
			break;
		case 6:
			glReadPixels(x, y, width, height, GL_BGRA, GL_UNSIGNED_INT_10_10_10_2, baseAddress);
			break;
		case 7:
			glReadPixels(x, y, width, height, GL_BGRA, GL_UNSIGNED_INT_2_10_10_10_REV, baseAddress);
			break;
		case 8:
			glReadPixels(x, y, width, height, GL_BGRA, GL_UNSIGNED_SHORT, baseAddress);
			break;
		case 9:
			glReadPixels(x, y, width, height, GL_BGRA, GL_SHORT, baseAddress);
			break;
		default:
			break;
	}
	
    glPopClientAttrib();
	
    //Check for OpenGL errors
    GLenum theError = GL_NO_ERROR;
    theError = glGetError();
    NSAssert1( theError == GL_NO_ERROR, @"OpenGL error 0x%04X", theError);
}

// Buffer manipulation
-(void)manipulateBuffer:(int)sr
{
	int i = 0;
	long loops = arc4random() % 200;
	
	while (i < loops) {
		
		if (arc4random() % 100 < 75) {
			
			long x, y, width, height;
			x = arc4random() % mWidth;
			y = arc4random() % mHeight;
			if (arc4random() % 100 < 10) {
				width = arc4random() % (mWidth-x);
			} else {
				width = mWidth;
			}
			if (arc4random() % 100 < 10) {
				height = arc4random() % (mHeight-y);
			} else {
				height = mHeight;
			}
			
			//NSLog(@"x: %d y: %d w: %d h: %d", x, y, width, height);
			
			[self readPartialScreenToBuffer:width bufferHeight:height bufferBaseAddress:mData posX:x posY:y safeOrRisky:sr];
		
		} else {
			
			long hx, hy;
			long hByteWidth, hWidth, hHeight;
			void *hData;
			
			hx = arc4random() % mWidth;
			hy = arc4random() % mHeight;
			
			hWidth = arc4random() % (mWidth-hx);
			hHeight = arc4random() % (mHeight-hy);
			
			//NSLog(@"hx: %d hy: %d hw: %d hh: %d", hx, hy, hWidth, hHeight);
			
			hByteWidth = hWidth * 4;                // Assume 4 bytes/pixel for now
			hByteWidth = (hByteWidth + 3) & ~3;    // Align to 4 bytes
			
			hData = malloc(hByteWidth * hHeight);
			NSAssert( hData != 0, @"malloc failed");
			
			
			glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_UNSIGNED_INT_2_10_10_10_REV, hData);
			
			//Read a block of pixels from the frame buffer
			long modes = 10;
			
			if (sr == 0) {
				modes = 8;
			}
			
			long bitMode = arc4random() % modes;
			
			//NSLog(@"mode: %d", bitMode);
			
			switch (bitMode) {
				case 0:
					glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_UNSIGNED_SHORT_4_4_4_4, hData);
					break;
				case 1:
					glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_UNSIGNED_SHORT_4_4_4_4_REV, hData);
					break;
				case 2:
					glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_UNSIGNED_SHORT_5_5_5_1, hData);
					break;
				case 3:
					glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_UNSIGNED_SHORT_1_5_5_5_REV, hData);
					break;
				case 4:
					glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, hData);
					break;
				case 5:
					glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, hData);
					break;
				case 6:
					glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_UNSIGNED_INT_10_10_10_2, hData);
					break;
				case 7:
					glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_UNSIGNED_INT_2_10_10_10_REV, hData);
					break;
				case 8:
					glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_UNSIGNED_SHORT, hData);
					break;
				case 9:
					glReadPixels(hx, hy, hWidth, hHeight, GL_BGRA, GL_SHORT, hData);
					break;
				default:
					break;
			}
			
			
			long row, lastRow;
			void * hP;
			void * mP;
			void * hBase;
			void * mBase;
			long hRowBytes;
			long mRowBytes;
			
			row = hy;
			lastRow = hy + hHeight;		
			hBase = hData;		
			mBase = mData;
			
			hRowBytes = hByteWidth;
			mRowBytes = mByteWidth;
			
			while (row < lastRow)
			{			
				hP = (void *)(((row-hy) * hRowBytes) + (intptr_t)hBase);
				//NSLog(@"hP: %d", hP);
				mP = (void *)(hx + (row * mRowBytes) + (intptr_t)mBase);
				//NSLog(@"mP: %d", mP);
				/*
				 * Save and swap scanlines.
				 *
				 * This code does a simple in-place exchange with a temp buffer.
				 * If you need to reformat the pixels, replace the first two bcopy()
				 * calls with your own custom pixel reformatter.
				 */
				bcopy( hP, mP, hRowBytes );
				
				++row;
			}		
			
			free(hData);
		}
	
		
		
		++i;
	}
}

// Create a TIFF file on the desktop from our data buffer
-(void)createTIFFImageFileOnDesktop
{
    // glReadPixels writes things from bottom to top, but we
    // need a top to bottom representation, so we must flip
    // the buffer contents.
    [self flipImageData];

    // Create a Quartz image from our pixel buffer bits
    CGImageRef imageRef = [self createRGBImageFromBufferData];
    NSAssert( imageRef != 0, @"cgImageFromPixelBuffer failed");

    // Make full pathname to the desktop directory
    NSString *desktopDirectory = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains
                        (NSDesktopDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0)  
    {
        desktopDirectory = [paths objectAtIndex:0];
    }
	
	NSDate *now = [NSDate date];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"Y-M-d_H-m-S"];
	
	NSString *appName = @"/ScreenFucked_";
	NSString *stringFromDate = [formatter stringFromDate:now];
	NSString *fileType = @".tiff";
	
    NSMutableString *fullFilePathStr = [NSMutableString stringWithString:desktopDirectory];
    NSAssert( fullFilePathStr != nil, @"stringWithString failed");
	NSString *fileName = [appName stringByAppendingString:stringFromDate];
	NSString *fileNameAndType = [fileName stringByAppendingString:fileType];
    [fullFilePathStr appendString:fileNameAndType];

    NSString *finalPath = [NSString stringWithString:fullFilePathStr];
    NSAssert( finalPath != nil, @"stringWithString failed");

    CFURLRef url = CFURLCreateWithFileSystemPath (
												kCFAllocatorDefault,
												(CFStringRef)finalPath,
												kCFURLPOSIXPathStyle,
												false);
    NSAssert( url != 0, @"CFURLCreateWithFileSystemPath failed");
    // Save our screen bits to an image file on disk

    // Save the image to the file
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, CFSTR("public.tiff"), 1, nil);
    NSAssert( dest != 0, @"CGImageDestinationCreateWithURL failed");

    // Set the image in the image destination to be `image' with
    // optional properties specified in saved properties dict.
    CGImageDestinationAddImage(dest, imageRef, nil);
    
    bool success = CGImageDestinationFinalize(dest);
    NSAssert( success != 0, @"Image could not be written successfully");

    CFRelease(dest);
    CGImageRelease(imageRef);
    CFRelease(url);
}

#pragma mark ---------- Cleanup  ----------

-(void)dealloc
{    
    // Get rid of GL context
    [NSOpenGLContext clearCurrentContext];
    // disassociate from full screen
    [mGLContext clearDrawable];
    // and release the context
    [mGLContext release];
	// release memory for screen data
	free(mData);

    [super dealloc];
}

@end

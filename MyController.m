 /*
 
 File: MyController.m
 
 */ 

#import "MyController.h"

@implementation MyController

//SAFE should not crash
- (IBAction)screenSnapshotSafe:(id)sender
{
    // Create a screen reader object
    screenFuck = [[ScreenFuck alloc] init];
    NSAssert( screenFuck != 0, @"ScreenFuck alloc failed");
	
	int sr = 0;
	
    // Read the screen bits
    [screenFuck readFullScreenToBuffer:sr];
	
	// Bufferfucker		
	[screenFuck manipulateBuffer:sr];

    // Write our image to a TIFF file on disk
    [screenFuck createTIFFImageFileOnDesktop];

    // Finished, so let's cleanup
    [screenFuck release];
    screenFuck = nil;
}

//SAFE may crash sometimes
- (IBAction)screenSnapshotRisky:(id)sender
{
    // Create a screen reader object
    screenFuck = [[ScreenFuck alloc] init];
    NSAssert( screenFuck != 0, @"ScreenFuck alloc failed");
	
	int sr = 1;
	
    // Read the screen bits
    [screenFuck readFullScreenToBuffer:sr];
	
	// Bufferfucker		
	[screenFuck manipulateBuffer:sr];
	
    // Write our image to a TIFF file on disk
    [screenFuck createTIFFImageFileOnDesktop];
	
    // Finished, so let's cleanup
    [screenFuck release];
    screenFuck = nil;
}

@end

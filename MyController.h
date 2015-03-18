 /*
 
 File: MyController.h
 
 */ 
 
#import <Cocoa/Cocoa.h>
#import "ScreenFuck.h"

@interface MyController : NSObject
{
    ScreenFuck *screenFuck;
}

- (IBAction)screenSnapshotSafe:(id)sender;
- (IBAction)screenSnapshotRisky:(id)sender;

@end

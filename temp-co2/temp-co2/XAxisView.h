//
//  XAxisView.h
//  temp-co2
//
//  Created by david on 5/22/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class Recents;

@interface XAxisView : NSView

- (void)showRecents:(Recents *)recents;

@end

NS_ASSUME_NONNULL_END

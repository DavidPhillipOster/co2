//
//  XAxisView.h
//  temp-co2
//
//  Created by david on 5/22/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class Recents;

@protocol MouseDownProtocol;

@interface XAxisView : NSView

@property (weak) IBOutlet id<MouseDownProtocol> delegate;

- (void)showRecents:(Recents *)recents;

@end

@protocol MouseDownProtocol <NSObject>
- (void)setIsMouseDown:(BOOL)isDown;
@end

NS_ASSUME_NONNULL_END

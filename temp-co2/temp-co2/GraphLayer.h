//
//  GraphLayer.h
//  temp-co2
//
//  Created by david on 5/20/21.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@class Recents;

@interface GraphLayer : CAShapeLayer

- (void)showRecents:(Recents *)recents;

@end

NS_ASSUME_NONNULL_END

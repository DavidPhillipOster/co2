//
//  CO2Manager.h
//  temp-co2
//
//  Created by david on 6/08/2021
// Apache license. See LICENSE file.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Coordinate collecting data from the device, appending it to the model, and displaying the result.
@interface CO2Manager : NSResponder

/// defaults to 800 - yellow window
@property(nonatomic) CGFloat warningThreshold;

/// defaults to 1200 must be larger than warning. - red window
@property(nonatomic) CGFloat dangerThreshold;

- (void)setup;
- (void)shutdown;
@end

NS_ASSUME_NONNULL_END

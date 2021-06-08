//
//  Recents.h
//  temp-co2
//
//  Created by david on 5/19/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Reading;

typedef struct TimedCO2 {
  NSTimeInterval when;
  CGFloat co2;
} TimedCO2;

typedef struct TimedTemp {
  NSTimeInterval when;
  CGFloat temp;
} TimedTemp;


/// A history of recent readings from the hardware. Will be used to draw a graph in the U.I. Saved in Application Support
@interface Recents : NSObject
@property(nonatomic, readonly) NSUInteger count;

- (Reading *)readingAtIndex:(NSUInteger)index;

- (void)addCo2:(CGFloat)temp when:(NSTimeInterval)when;
- (void)addTemp:(CGFloat)temp when:(NSTimeInterval)when;

- (instancetype)initWithDictionary:(nullable NSDictionary *)dict;
- (NSDictionary *)asDictionary;

// Returns 0,0 if not found.
- (void)getCO2Min:(TimedCO2 *)outMin max:(TimedCO2 *)outMax;

// Returns 0,0 if not found.
- (void)getTempMin:(TimedTemp *)outMin max:(TimedTemp *)outMax;

@end

NS_ASSUME_NONNULL_END

//  Reading.h
//  temp-co2
//
//  Created by david on 5/19/21.
// Apache license. See LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// A data structure representing one resding from the hardware.
@interface Reading : NSObject
@property(nonatomic) CGFloat temp;
@property(nonatomic) CGFloat co2;
@property(nonatomic) NSTimeInterval timeOfLastReading;

- (instancetype)initWithDictionary:(nullable NSDictionary *)dict;

- (NSDictionary *)asDictionary;

@end

NS_ASSUME_NONNULL_END

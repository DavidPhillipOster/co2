//
//  Recents.h
//  temp-co2
//
//  Created by david on 5/19/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Reading;

@interface Recents : NSObject
@property(nonatomic, readonly) NSUInteger count;

- (Reading *)readingAtIndex:(NSUInteger)index;

- (void)addCo2:(CGFloat)temp when:(NSTimeInterval)when;
- (void)addTemp:(CGFloat)temp when:(NSTimeInterval)when;

- (instancetype)initWithDictionary:(nullable NSDictionary *)dict;
- (NSDictionary *)asDictionary;

@end

NS_ASSUME_NONNULL_END

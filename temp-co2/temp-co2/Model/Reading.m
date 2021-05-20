//  Reading.m
//  temp-co2
//
//  Created by david on 5/19/21.
// Apache license. See LICENSE file.

#import "Reading.h"

static NSString *const kTemp = @"temp";
static NSString *const kCO2 = @"co2";
static NSString *const kWhen = @"when";

@implementation Reading

- (instancetype)initWithDictionary:(NSDictionary *)dict {
  self = [self init];
  NSNumber *n = dict[kTemp];
  self.temp = [n floatValue];
  n = dict[kCO2];
  self.co2 = [n floatValue];
  n = dict[kWhen];
  self.timeOfLastReading = [n doubleValue];
  return self;
}

- (NSDictionary *)asDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  if (self.temp) {
    dict[kTemp] = @(self.temp);
  }
  if (self.co2) {
   dict[kCO2] = @(self.co2);
  }
  if (self.timeOfLastReading) {
    dict[kWhen] = @(self.timeOfLastReading);
  }
  return dict;
}


@end


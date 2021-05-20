//
//  Recents.m
//  temp-co2
//
//  Created by david on 5/19/21.
//

#import "Recents.h"
#import "Reading.h"

static NSString *const kReadings = @"readings";

static const NSUInteger kMaxItems = 256;
static const NSTimeInterval kCoalesceTime = 2*60;

@interface Recents ()
@property(nonatomic) NSMutableArray<Reading *> *readings;
@end

@implementation Recents

- (instancetype)init {
  self = [super init];
  if (self) {
    _readings = [[NSMutableArray alloc] init];
  }
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
  self = [self init];
  NSArray<NSDictionary *> *carrier = dict[kReadings];
  if ([carrier respondsToSelector:@selector(objectAtIndex:)]) {
    NSMutableArray<Reading *> *t = [NSMutableArray array];
    for (NSDictionary *dict in carrier) {
      Reading *reading = [[Reading alloc] initWithDictionary:dict];
      if (reading.timeOfLastReading != 0.0 && (reading.temp != 0.0 || reading.co2 != 0.0)) {
        [t addObject:reading];
      }
    }
    self.readings = t;
  }
  return self;
}

- (NSDictionary *)asDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSMutableArray<NSDictionary *> *carrier = [NSMutableArray array];
  for (Reading *reading in self.readings) {
    NSDictionary *dict = [reading asDictionary];
    [carrier addObject:dict];
  }
  dict[kReadings] = carrier;
  return dict;
}

- (NSUInteger)count {
  return self.readings.count;
}

- (Reading *)readingAtIndex:(NSUInteger)index {
  return [self.readings objectAtIndex:index];
}

- (void)addTemp:(CGFloat)temp co2:(CGFloat)co2 when:(NSTimeInterval)when {
  Reading *reading = self.readings.lastObject;
  if (nil == reading || kCoalesceTime < when - reading.timeOfLastReading) {
    reading = [[Reading alloc] init];
    [self.readings addObject:reading];
    if(kMaxItems < self.readings.count) {
      [self.readings removeObjectAtIndex:0];
    }
  }
  if (temp != 0.0) {
    reading.temp = temp;
  }
  if (co2 != 0.0) {
    reading.co2 = co2;
  }
  reading.timeOfLastReading = when;
}

// ignore zero readings.
- (void)addCo2:(CGFloat)co2 when:(NSTimeInterval)when {
  if (co2 != 0.0) {
    [self addTemp:0 co2:co2 when:when];
  }
}

// ignore zero readings.
- (void)addTemp:(CGFloat)temp when:(NSTimeInterval)when {
  if (temp != 0.0) {
    [self addTemp:temp co2:0 when:when];
  }
}



@end

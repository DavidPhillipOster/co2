//
//  AppDelegate.m
//  temp-co2
//
//  Created by david on 10/2/20.
// Apache license. See LICENSE file.


#import "AppDelegate.h"

#include "hidapi.h" // at: https://github.com/signal11/hidapi  BSD License
#include "holtekco2.h" // at: https://github.com/vshmoylov/libholtekco2 MIT License

@interface AppDelegate ()

@property IBOutlet NSWindow *window;
@property IBOutlet NSView *contentView;
@property IBOutlet NSTextField *label;
@property IBOutlet NSTextField *iconLabel;

// non-main-thread Database operations on the dbQueue // for Mac
@property NSOperationQueue *hardwareQueue;

@property(nonatomic) CGFloat temp;
@property(nonatomic) CGFloat co2;
@property(nonatomic) NSTimeInterval timeOfLastReading;
@property(nonatomic) NSTimer *timer;
@property co2_device *device;
@end

NSString *MakeLegend(CGFloat temp, CGFloat co2) {
  NSString *tempS = temp <= 0 ? @" - " : [NSString stringWithFormat:@"%3.1f°", temp];
  NSString *co2S = co2 <= 0 ?  @" - " : [NSString stringWithFormat:@"%3.0f", co2];
  NSString *result = [NSString stringWithFormat:@"%@%@%@%@", @"Temp: ", tempS, @"\nCO₂ ppm: ", co2S];
  return result;
}
NSString *MakeIconLegend(CGFloat temp, CGFloat co2) {
  NSString *tempS = temp <= 0 ? @" - " : [NSString stringWithFormat:@"%3.1f°", temp];
  NSString *co2S = co2 <= 0 ?  @" - " : [NSString stringWithFormat:@"%3.0f", co2];
  NSString *result = [NSString stringWithFormat:@"%@\n%@ ", tempS, co2S];
  return result;
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  self.hardwareQueue = [self constructWorkQueueWithQuality:NSQualityOfServiceUtility];
  self.contentView.layer.backgroundColor = [[NSColor systemBlueColor] CGColor];
  self.label.stringValue = MakeLegend(self.temp, self.co2);
  __weak typeof(self) weakSelf = self;
  [self.hardwareQueue addOperationWithBlock:^{
    [weakSelf takeReadingSet];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [weakSelf startTimer];
    }];
  }];
}

- (NSOperationQueue *)constructWorkQueueWithQuality:(NSQualityOfService)quality {
  NSOperationQueue *workQueue = [[NSOperationQueue alloc] init];
  workQueue.qualityOfService = quality;
  workQueue.maxConcurrentOperationCount = 1;
  return workQueue;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  if (self.device) {
    co2_close(self.device);
    self.device = nil;
    hid_exit();
  }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (void)startTimer {
  self.timer = [NSTimer scheduledTimerWithTimeInterval:3*60 repeats:YES block:^(NSTimer *timer) {
    [self.hardwareQueue addOperationWithBlock:^{ if (self.device == nil) { [self takeReadingSet]; } }];
  }];
}

// Called on hardwareQueue
- (void)takeReadingSet {
  hid_init();
  self.device = co2_open_first_device();
  for (int i = 0; i < 10; ++i) {
    [self takeReading];
  }
  if (self.device) {
    co2_close(self.device);
    self.device = nil;
  }
  hid_exit();
}

// Called on hardwareQueue
- (void)takeReading {
  if (self.device) {
    co2_device_data device_data = co2_read_data(self.device);
    if (device_data.valid) {
      if (device_data.tag == CO2) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          self.co2 = device_data.value;
        }];
      } else if (device_data.tag == TEMP) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          self.temp = co2_get_fahrenheit_temp(device_data.value);
        }];
      }
    }
  }
}

- (void)setCo2:(CGFloat)co2 {
  _co2 = co2;
  self.timeOfLastReading = [NSDate timeIntervalSinceReferenceDate];
  [self update];
}

- (void)setTemp:(CGFloat)temp {
  _temp = temp;
  self.timeOfLastReading = [NSDate timeIntervalSinceReferenceDate];
  [self update];
}

- (void)update {
  // If we've lost connection to the device for longer than two read intervals, then update the display to say so.
  if ((6*60)+5 < [NSDate timeIntervalSinceReferenceDate] - self.timeOfLastReading) {
    _co2 = 0;
    _temp = 0;
  }
  self.label.stringValue = MakeLegend(self.temp, self.co2);
  [self drawDockImage];
}

- (void)drawDockImage {
  NSImage *iconImage = [[NSImage imageNamed:@"iconBlank.png"] copy];
  [iconImage lockFocus];
  CGRect frame = NSMakeRect(3, 3, 118, 95);
  CGRect bounds = frame;
  self.iconLabel.stringValue = MakeIconLegend(self.temp, self.co2);
  bounds.origin = CGPointZero;
  [self.iconLabel setFrame:frame];
  [self.iconLabel drawRect:bounds];
  [iconImage unlockFocus];
  [NSApp setApplicationIconImage:iconImage];
}

@end

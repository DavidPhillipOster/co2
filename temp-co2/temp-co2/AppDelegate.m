//
//  AppDelegate.m
//  temp-co2
//
//  Created by david on 10/2/20.
// Apache license. See LICENSE file.


#import "AppDelegate.h"

#include "hidapi.h" // at: https://github.com/signal11/hidapi  BSD License
#include "holtekco2.h" // at: https://github.com/vshmoylov/libholtekco2 MIT License
#import "GraphLayer.h"
#import "Reading.h"
#import "Recents.h"
#import "RecentsIO.h"
#import "XAxisView.h"

static NSString *IntervalAsDateString(NSTimeInterval when) {
  NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:when];
  return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
}

@interface AppDelegate () <MouseDownProtocol>

@property IBOutlet NSWindow *window;
@property IBOutlet NSView *contentView;
@property IBOutlet NSTextField *label;
@property IBOutlet NSTextField *iconLabel;
@property IBOutlet NSTextField *statsLabel;
@property IBOutlet XAxisView *xAxisView;

// non-main-thread Database operations on the dbQueue // for Mac
@property NSOperationQueue *hardwareQueue;
@property Reading *reading;
@property Recents *recents;
@property GraphLayer *graphLayer;
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
  [self setBackgroundColor];
  self.graphLayer = [[GraphLayer alloc] init];
  self.graphLayer.frame = self.contentView.layer.bounds;
  self.xAxisView.delegate = self;
  // addLayer: makes it cover the label text.
  [self.contentView.layer insertSublayer:self.graphLayer below:self.xAxisView.layer];
  NSDictionary *history = ReadHistory();
  self.recents = [[Recents alloc] initWithDictionary:history];
  self.reading = [[Reading alloc] init];
  self.statsLabel.frame = self.label.superview.bounds;
  [self.label.superview addSubview:self.statsLabel];
  [self.statsLabel setHidden:YES];
  self.label.stringValue = MakeLegend(self.reading.temp, self.reading.co2);
  if (@available(macOS 10.15, *)) {
    [NSApp addObserver:self forKeyPath:@"effectiveAppearance" options:0 context:(__bridge void *)(self)];
  }
  __weak typeof(self) weakSelf = self;
  [self.hardwareQueue addOperationWithBlock:^{
    [weakSelf takeReadingSet];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [weakSelf startTimer];
    }];
  }];
}

// The label in the dock tile doesn't pick up the current appearance, so we set its text color explicitly when the app's appearance changes.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  if (object == NSApp && context == (__bridge void *)(self) && [keyPath isEqual:@"effectiveAppearance"]) {
    if (@available(macOS 10.15, *)) {
      // In dark mode, textColor is too black. Pick a lighter gray.
      self.iconLabel.textColor = [NSAppearanceNameDarkAqua isEqual:NSApp.effectiveAppearance.name] ?
        [NSColor colorWithWhite:16.0/255 alpha:1] : [NSColor textBackgroundColor];
      [self drawDockImage];
    }
  }
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
  if (self.recents.count) {
    WriteHistory(self.recents.asDictionary);
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

/// Set the background color to mirror the yellow or red LED on the monitor.
- (void)setBackgroundColor {
  struct CGColor *color = [[NSColor systemBlueColor] CGColor];
  if (1200 < self.reading.co2) {
    color = [[NSColor systemRedColor] CGColor];
  } else if (800 < self.reading.co2) {
    color = [[NSColor systemYellowColor] CGColor];
  }
  self.contentView.layer.backgroundColor = color;
}

- (void)setCo2:(CGFloat)co2 {
  self.reading.co2 = co2;
  self.reading.timeOfLastReading = [NSDate timeIntervalSinceReferenceDate];
  [self.recents addCo2:co2 when:self.reading.timeOfLastReading];
  [self update];
}

- (void)setTemp:(CGFloat)temp {
  self.reading.temp = temp;
  self.reading.timeOfLastReading = [NSDate timeIntervalSinceReferenceDate];
  [self.recents addTemp:temp when:self.reading.timeOfLastReading];
  [self update];
}

// a table of min and max values, with times, as attributed tab separated values
- (NSAttributedString *)statistics {
    TimedCO2 min, max;
    [self.recents getCO2Min:&min max:&max];
    NSString *missing = @" - ";
    NSString *minCO2S = min.co2 != 0.0 ? [@((int)min.co2) stringValue] : missing;
    NSString *minCO2Date = min.when != 0.0 ? IntervalAsDateString(min.when) : missing;
    NSString *maxCO2S = max.co2 != 0.0 ? [@((int)max.co2) stringValue] : missing;
    NSString *maxCO2Date = max.when != 0.0 ? IntervalAsDateString(max.when) : missing;
    NSString *co2Name = @"CO₂";
    NSString *co2S = [NSString stringWithFormat:@"%@\tppm\t\twhen\nmax:\t%@\t\t%@\nmin:\t%@\t\t%@\n",
      co2Name, maxCO2S, maxCO2Date, minCO2S, minCO2Date];
    TimedTemp minT, maxT;
    [self.recents getTempMin:&minT max:&maxT];
    NSString *minTS = minT.temp != 0.0 ? [NSString stringWithFormat:@"%3.1f", minT.temp]: missing;
    NSString *minTDate = minT.when != 0.0 ? IntervalAsDateString(minT.when) : missing;
    NSString *maxTS = maxT.temp != 0.0 ? [NSString stringWithFormat:@"%3.1f", maxT.temp]: missing;
    NSString *maxTDate = maxT.when != 0.0 ? IntervalAsDateString(maxT.when) : missing;
    NSString *tempName = @"temp";
    NSString *tempS = [NSString stringWithFormat:@"%@\t°F\t\twhen\nmax:\t%@\t\t%@\nmin:\t%@\t\t%@",
      tempName, maxTS, maxTDate, minTS, minTDate];
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.tabStops = @[
      [[NSTextTab alloc] initWithType:NSRightTabStopType location:70],
      [[NSTextTab alloc] initWithType:NSLeftTabStopType location:80],
      [[NSTextTab alloc] initWithType:NSLeftTabStopType location:85],
      [[NSTextTab alloc] initWithType:NSLeftTabStopType location:90]
    ];
    NSDictionary *attr = @{
      NSFontAttributeName : [NSFont systemFontOfSize:14],
      NSForegroundColorAttributeName : [NSColor textBackgroundColor],
      NSParagraphStyleAttributeName : para,
    };
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:co2S attributes:attr];
    [as addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:14] range:NSMakeRange(0, co2Name.length)];
    NSMutableAttributedString *ats = [[NSMutableAttributedString alloc] initWithString:tempS attributes:attr];
    [ats addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:14] range:NSMakeRange(0, tempName.length)];
    [as appendAttributedString:ats];
    return as;
}

- (void)setIsMouseDown:(BOOL)isDown {
  if (isDown) {
    self.statsLabel.attributedStringValue = [self statistics];
  }
  self.label.hidden = isDown;
  self.statsLabel.hidden = ! isDown;
}

- (void)copy:(id)sender {
  if ( ! self.statsLabel.isHidden) {
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard clearContents];
    NSMutableAttributedString *as = [self.statsLabel.attributedStringValue mutableCopy];
    if (as.length) {
      [as addAttribute:NSForegroundColorAttributeName value:[NSColor textColor] range:NSMakeRange(0, as.length)];
      NSData *data = [as RTFFromRange:NSMakeRange(0, as.length) documentAttributes:@{}];
      if (data) {
        [pasteBoard setData:data forType:NSPasteboardTypeRTF];
        return;
      }
    }
  }
  NSString *s = self.label.stringValue;
  if (s.length) {
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard clearContents];
    [pasteBoard writeObjects:@[s]];
  }
}

- (void)update {
  // If we've lost connection to the device for longer than two read intervals, then update the display to say so.
  if ((6*60)+5 < [NSDate timeIntervalSinceReferenceDate] - self.reading.timeOfLastReading) {
    self.reading.co2 = 0;
    self.reading.temp = 0;
  }
  [self setBackgroundColor];
  self.label.stringValue = MakeLegend(self.reading.temp, self.reading.co2);
  [self drawDockImage];
  [self.graphLayer showRecents:self.recents];
  [self.xAxisView showRecents:self.recents];
}

- (void)drawDockImage {
  NSImage *iconImage = [[NSImage imageNamed:@"iconBlank.png"] copy];
  [iconImage lockFocus];
  CGRect frame = NSMakeRect(3, 3, 118, 95);
  CGRect bounds = frame;
  self.iconLabel.stringValue = MakeIconLegend(self.reading.temp, self.reading.co2);
  bounds.origin = CGPointZero;
  [self.iconLabel setFrame:frame];
  [self.iconLabel drawRect:bounds];
  [iconImage unlockFocus];
  [NSApp setApplicationIconImage:iconImage];
}

@end

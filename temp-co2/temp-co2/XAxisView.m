//
//  XAxisView.m
//  temp-co2
//
//  Created by david on 5/22/21.
//

#import "XAxisView.h"

#import "EdgeInset.h"
#import "Reading.h"
#import "Recents.h"

@interface LegendItem : NSObject
@property CGPoint p;
@property NSString *text;
@end
@implementation LegendItem
@end

@interface XAxisView ()
@property NSEdgeInsets inset;
@property NSFont *font;
@property NSColor *textColor;
@property NSMutableArray<LegendItem *> *legends;
@property NSDictionary *attrs;
@property(nonatomic) BOOL isMouseDown;
@end

@implementation XAxisView

- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  [self xAxisViewInit];
  return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  [self xAxisViewInit];
  return self;
}

- (void)xAxisViewInit {
  _inset = GraphInset();
  _font = [NSFont systemFontOfSize:9];
  _textColor = [NSColor whiteColor];
  _legends = [[NSMutableArray alloc] init];
  _attrs = @{NSFontAttributeName : self.font, NSForegroundColorAttributeName : self.textColor};
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];
  for (LegendItem *item in self.legends) {
    [item.text drawAtPoint:item.p withAttributes:self.attrs];
  }
}

- (void)showRecents:(Recents *)recents {
  CGRect bounds = self.bounds;
  if (2 <= recents.count && 0 < bounds.size.height && 3 < bounds.size.width) {
    [self.legends removeAllObjects];
    NSInteger i = recents.count - 1;
    // - 10 so we don't draw text too close to the edge of the window.
    NSInteger lastX = bounds.size.width - self.inset.right - 10;
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *parts = [calendar
      components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour
        fromDate:now];
    parts.hour = (parts.hour/3) * 3;
    // label the sample closest to 3,6,9,12 o'clock.
    NSDate *labelDate = [calendar dateFromComponents:parts];
    NSTimeInterval labelTimeInterval = [labelDate timeIntervalSinceReferenceDate];
    NSTimeInterval lastTimeDifference = MAXFLOAT;
    // + 10 so we don't draw text too close to the edge of the window.
    for (NSInteger x = lastX; self.inset.left + 10 <= x && 0 <= i; --x, --i ) {
      Reading *r = [recents readingAtIndex:i];
      NSTimeInterval diff = r.timeOfLastReading - labelTimeInterval;
      if (0 < diff && diff < lastTimeDifference) {
        lastX = x;
        lastTimeDifference = diff;
      } else if (diff < 0) {
        if (0 == self.legends.count || 10 < self.legends.lastObject.p.x - lastX) {
          LegendItem *item = [[LegendItem alloc] init];
          item.p = CGPointMake(lastX, 5);
          item.text = [NSString stringWithFormat:@"%ld", (24 == parts.hour || 0 == parts.hour) ? 12L : parts.hour];
          [self.legends addObject:item];
        }
        if (0 == parts.hour) {
          parts.hour = 24;
        }
        parts.hour -= 3;
        if (parts.hour <= 0) {
          parts.hour = 24;
          parts.day -= 1;
          labelDate = [calendar dateFromComponents:parts];
          labelTimeInterval = [labelDate timeIntervalSinceReferenceDate];
        }
        lastX = x;
        lastTimeDifference = MAXFLOAT;
        labelTimeInterval = [[calendar dateFromComponents:parts] timeIntervalSinceReferenceDate];
      }
    }
    [self setNeedsDisplay:YES];
  }
}

// Since this view covers the whole window, make it respond to mouse clicks.
//
- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)mouseDown:(NSEvent *)event {
  self.isMouseDown = YES;
}

- (void)mouseUp:(NSEvent *)event {
  self.isMouseDown = NO;
}

- (void)setIsMouseDown:(BOOL)isDown {
  if (self.isMouseDown != isDown) {
    _isMouseDown = isDown;
    [self.delegate setIsMouseDown:isDown];
  }
}

@end

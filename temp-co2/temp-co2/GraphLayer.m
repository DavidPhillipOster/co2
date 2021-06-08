//
//  GraphLayer.m
//  temp-co2
//
//  Created by david on 5/20/21.
//

#import "GraphLayer.h"

#import "EdgeInset.h"
#import "Reading.h"
#import "Recents.h"

#import <AppKit/AppKit.h>

@interface GraphLayer ()
@property NSEdgeInsets inset;
@property CGFloat co2Max;
@property CGFloat co2Min;
@end

@implementation GraphLayer

- (instancetype)init {
  self = [super init];
  self.fillColor = [[NSColor colorWithRed:169.0/255.0 green:197.0/255.0 blue:242.0/255.0 alpha:1] CGColor];
  self.strokeColor = NSColor.clearColor.CGColor;
  self.inset = GraphInset();
  self.co2Max = 1400;
  self.co2Min = 300;
  return self;
}

- (void)showRecents:(Recents *)recents {
  [self showRecentsFillCO2:recents];
}

/// Show the CO2 data as a right-aligned filled polygon CGPath of the layer, using the instance's scalng parameters
- (void)showRecentsFillCO2:(Recents *)recents {
  CGRect bounds = self.bounds;
  if (2 <= recents.count && 0 < bounds.size.height && 3 < bounds.size.width) {
    CGFloat scale = (bounds.size.height - (self.inset.top+self.inset.bottom))/(self.co2Max - self.co2Min);
    CGMutablePathRef path = CGPathCreateMutable();
    NSInteger i = recents.count - 1;
    NSInteger lastX = bounds.size.width - self.inset.right;
    for (NSInteger x = lastX; self.inset.left <= x && 0 <= i; --x, --i ) {
      Reading *r = [recents readingAtIndex:i];
      if (r.co2 != 0) {
        CGFloat co2 = MAX(self.co2Min, MIN(self.co2Max, r.co2)) - self.co2Min;
        CGFloat y = co2 * scale + self.inset.bottom;
        CGPoint p = CGPointMake(x, y);
        if (CGPathIsEmpty(path)) {
          CGPathMoveToPoint(path, nil, p.x, self.inset.bottom);
        }
        CGPathAddLineToPoint(path, nil, p.x, p.y);
        lastX = x;
      }
    }
    CGPathAddLineToPoint(path, nil, lastX, self.inset.bottom);
    CGPathCloseSubpath(path);
    self.path = path;
    CGPathRelease(path);
  }
}

@end

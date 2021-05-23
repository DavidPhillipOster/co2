// RecentsIO.m
// Apache license. See LICENSE file.
//  Created by david on 5/19/21.
#import "RecentsIO.h"

/// The URL to the history file. Create subdirectories as needed. nil on failure.
static NSURL *_Nullable HistoryURL(){
  NSFileManager *fm = [NSFileManager defaultManager];
  NSURL *supportDir = [[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
  if (supportDir) {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    supportDir = [supportDir URLByAppendingPathComponent:bundleID];
    [fm createDirectoryAtPath:[supportDir path] withIntermediateDirectories:YES attributes:nil error:NULL];
    return [supportDir URLByAppendingPathComponent:@"history.plist"];
  }
  return nil;
}

/// The contents of the history file, or nil if it doesn't exist, couldn't be read.
NSDictionary *_Nullable ReadHistory() {
  NSURL *historyURL = HistoryURL();
  if (historyURL) {
    return [NSDictionary dictionaryWithContentsOfURL:historyURL];
  }
  return nil;
}

/// Attempt to write the dictionary to the history file. Silently ignore errors.
void WriteHistory(NSDictionary *dict) {
  if (dict) {
    NSURL *historyURL = HistoryURL();
    if (historyURL) {
      [dict writeToURL:historyURL atomically:YES];
    }
  }
}


#import "RecentsIO.h"

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

 NSDictionary *_Nullable ReadHistory() {
  NSURL *historyURL = HistoryURL();
  if (historyURL) {
    return [NSDictionary dictionaryWithContentsOfURL:historyURL];
  }
  return nil;
}

void WriteHistory(NSDictionary *dict) {
  if (dict) {
    NSURL *historyURL = HistoryURL();
    if (historyURL) {
      [dict writeToURL:historyURL atomically:YES];
    }
  }
}


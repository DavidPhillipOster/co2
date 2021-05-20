#import <Cocoa/Cocoa.h>

// Read the history from a .plist in subdirectory of Application Support
NSDictionary *_Nullable ReadHistory(void);

// Write the history from a .plist in subdirectory of Application Support
void WriteHistory(NSDictionary *_Nullable dict);

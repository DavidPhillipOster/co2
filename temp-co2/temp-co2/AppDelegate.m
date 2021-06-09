//
//  AppDelegate.m
//  temp-co2
//
//  Created by david on 10/2/20.
// Apache license. See LICENSE file.


#import "AppDelegate.h"

#import "CO2Manager.h"

@interface AppDelegate ()

@property IBOutlet NSWindow *window;
@property IBOutlet CO2Manager *co2Manager;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self.co2Manager setup];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  [self.co2Manager shutdown];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

@end

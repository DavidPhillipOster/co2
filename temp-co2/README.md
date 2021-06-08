#  temp-co2
6/07/2021
Version 2.2
Dark mode support. Window backgound color turns yellow and red when the LED on the box turns yellow or red.

5/24/2021
Version 2.1
Hold the mouse down on the window to see the statistics. You can <command>-c even when the mouse is down to copy the statistics.

5/19/2021
Version 2
Saves the most recent 256 reading pairs in an array in memory and on disk. Graph the CO2 history.

10/02/2020
Version 1.
Also draws the info in the Dock. Updates every 3 minutes. Blanks the display if looses contact with the device for more than 6 minutes,.

TODO: Should temperature be graphed? Longer term hstory? maybe also show daylight.

Lessons learned:
• I had to enable applescripting in the Info.plist to get the size of the window from applescript.
• I had to enable USB access in the signing&capabilities panel for it to access the USB devices.
• Leaving the HID open caused the app to crash after the timer went off to re-acquire the device.
• in macOS, the layer array of a view includes the layers of its subviews.
• NSTextField will consume mouse clicks, even if it is not enabled.

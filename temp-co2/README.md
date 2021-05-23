#  temp-co2
10/02/2020
Apache license. See LICENSE file.
Version 1.
Also draws the info in the Dock. Updates every 3 minutes. Blanks the display if looses contact with the device for more than 6 minutes,.

5/19/2021
Version 2
Saves the most recent 256 reading pairs in an array in memory and on disk. Graph the CO2 history.
TODO: needs time, skip gaps. and Y scale data., also temperature? maybe also show daylight.

Lessons learned:
• I had to enable applescripting in the Info.plist to get the size of the window from applescript.
• I had to enable USB access in the signing&capabilities panel for it to access the USB devices.
• Leaving the HID open caused the app to crash after the timer went off to re-acquire the device.



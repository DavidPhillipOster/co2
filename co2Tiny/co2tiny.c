#include <stdio.h>
#include "hidapi.h" // at: https://github.com/signal11/hidapi  BSD License
#include "holtekco2.h" // at: https://github.com/vshmoylov/libholtekco2 MIT License
// Thanks to: Henryk Plötz (https://hackaday.io/project/5301)
int main(int argc, const char * argv[]) { // MIT license
  hid_init();
  co2_device *device = co2_open_first_device();
  if (device) {
    for(;;) {
      co2_device_data device_data = co2_read_data(device);
      if (device_data.tag == CO2 && device_data.valid) {
        printf("%d ppm\n", device_data.value);
        break;
      }
    }
    co2_close(device);
  } else {
    fprintf(stderr, "device not found\n");
    return 1;
  }
  hid_exit();
  return 0;
}

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#include "hidapi.h" // at: https://github.com/signal11/hidapi  BSD License
#include "holtekco2.h" // at: https://github.com/vshmoylov/libholtekco2 MIT License
// Thanks to: Henryk Plötz (https://hackaday.io/project/5301)

enum {
  hasPPM = 1 << 0,
  hasTemp = 1 << 1,
  hasHumidity = 1 << 2,
  hasTimeStamp = 1 << 3,
};

typedef enum {
  ShowingTimeNo,
  ShowingTimeLocal,
  ShowingTimeGMT,
} ShowingTimeEnum;

// Data for one row of output.
typedef struct {
  uint16_t ppm;
  float temp;
  float humidity;
  time_t rawtime;
  unsigned char rowBits;
} Row;

// Options that can be set from the command line.
typedef struct {
  bool isShowingCO2;
  bool isShowingFahrenheit;
  bool isShowingHumidity;
  bool isShowingTemp;
  bool isVerbose;
  ShowingTimeEnum showingTime;
  int rowMax;
} Options;

void ReinitRow(Row *row) {
  time(&row->rawtime);
  row->rowBits |= hasTimeStamp;
}

// Write one row to the standard output
void FlushRow(Row *row, bool isVerbose, ShowingTimeEnum showingTime) {
  char ppmBuffer[64];
  char tempBuffer[64];
  char humidityBuffer[64];
  char timestampBuffer[64];
  char result[256];
  result[0] = '\0';
  struct tm timeBuffer;
  if (showingTime == ShowingTimeNo) {
    row->rowBits &= ~hasTimeStamp;
  }
  if (row->rowBits & hasPPM) {
    snprintf(ppmBuffer, sizeof ppmBuffer, "%d%s", row->ppm, isVerbose ? " ppm" : "");
    strncat(result, ppmBuffer, sizeof(result) - strlen(result) - 1);
    if (0 != (row->rowBits & ~hasPPM) ) {
      strncat(result, ",", sizeof(result) - strlen(result) - 1);
    }
  }
  if (row->rowBits & hasTemp) {
    snprintf(tempBuffer, sizeof tempBuffer, "%3.1f%s", row->temp, isVerbose ? "°" : "");
    strncat(result, tempBuffer, sizeof(result) - strlen(result) - 1);
    if (0 != (row->rowBits & ~(hasPPM|hasTemp)) ) {
      strncat(result, ",", sizeof(result) - strlen(result) - 1);
    }
  }
  if (row->rowBits & hasHumidity) {
    snprintf(humidityBuffer, sizeof humidityBuffer, "%3.1f%s", row->humidity, isVerbose ? "%%" : "");
    strncat(result, humidityBuffer, sizeof(result) - strlen(result) - 1);
    if (0 != (row->rowBits & ~(hasPPM|hasTemp|hasHumidity)) ) {
      strncat(result, ",", sizeof(result) - strlen(result) - 1);
    }
  }
  if (row->rowBits & hasTimeStamp) {
    strftime(timestampBuffer, sizeof timestampBuffer, "%D %R:%S", showingTime == ShowingTimeLocal ?
                    localtime_r(&row->rawtime, &timeBuffer) :
                    gmtime_r(&row->rawtime, &timeBuffer));
    strncat(result, timestampBuffer, sizeof(result) - strlen(result) - 1);
  }
  strncat(result, "\n", sizeof(result) - strlen(result) - 1);
  printf("%s", result);
  ReinitRow(row);
}

void Usage() {
  fprintf(stderr, "CO2 [ -c 50 ] [ -g -h -t ] - get readings from the first CO2 meter.\n"
  "version 1.0\n"
  "-c NNN  optional sample count. Default to 10 samples.\n"
  "-g time in GMT, not localtime \n"
  "-h include humidity (doesn't work with my hardware) \n"
  "-t include temperature\n"
  "-v verbose: include 'ppm' and '°' \n"
  "-C exclude CO2\n-D exclude date.\n-F Fahrenheit off i.e temperature in Celcius\n");
}

int ParseOptions(int argc, char * argv[], Options *options) {
  unsigned int ch;
  while ((ch = getopt(argc, argv, "c:ghtvCDF")) != -1) {
    switch (ch) {
      case 'c':
        options->rowMax = atoi(optarg);
        if (options->rowMax <= 0) {
          Usage();
          return 1;
        }
        break;
      case 'g':
        options->showingTime = ShowingTimeGMT;
        break;
      case 'h':
        options->isShowingHumidity = true;
        break;
      case 't':
        options->isShowingTemp = true;
        break;
      case 'v':
        options->isVerbose = true;
        break;
      case 'C':
        options->isShowingCO2 = false;
        break;
      case 'D':
        options->showingTime = ShowingTimeNo;
        break;
      case 'F':
        options->isShowingFahrenheit = false;
        break;
      default:
        Usage();
        return 1;
    }
  }
  // Nothing is turned on. Let the user know a mistake is being made.
  if (options->showingTime == ShowingTimeNo && !options->isShowingTemp && !options->isShowingCO2 && !options->isShowingHumidity ) {
    Usage();
    return 1;
  }
  return 0;
}

// Add one CO2 sample to the current row. But first, if we've already added that kind of sample to
// this row flush it to the output.
// returns 1 if did flush. else 0.
int AddOneCO2(const co2_device_data *device_data, const Options *options, Row *row) {
  int result = 0;
  if (options->isShowingCO2) {
    if (row->rowBits & hasPPM) {
      FlushRow(row, options->isVerbose, options->showingTime);
      result = 1;
    }
    row->ppm = device_data->value;
    row->rowBits |= hasPPM;
  }
  return result;
}

// Add one temperature sample to the current row. But first, if we've already added that kind of
// sample to this row flush it to the output.
// returns 1 if did flush. else 0.
int AddOneTemp(const co2_device_data *device_data, const Options *options, Row *row){
  int result = 0;
  if (options->isShowingTemp) {
    if (row->rowBits & hasTemp) {
      FlushRow(row, options->isVerbose, options->showingTime);
      result = 1;
    }
    if (options->isShowingFahrenheit) {
      row->temp = co2_get_fahrenheit_temp(device_data->value);
    } else {
      row->temp = co2_get_celsius_temp(device_data->value);
    }
    row->rowBits |= hasTemp;
  }
  return result;
}

// Add one humidity sample to the current row. But first, if we've already added that kind of
// sample to this row flush it to the output.
// returns 1 if did flush. else 0.
int AddOneHumidity(const co2_device_data *device_data, const Options *options, Row *row){
  int result = 0;
  if (options->isShowingHumidity) {
    if (row->rowBits & hasHumidity) {
      FlushRow(row, options->isVerbose, options->showingTime);
      result = 1 ;
    }
    row->humidity = co2_get_relative_humidity(device_data->value);
    row->rowBits |= hasHumidity;
  }
  return result;
}

// Add one sample to the current row. Bit first, if we've already added that kind of sample to this
// row flush it to the output.
// returns 1 is didflush. else 0.
int AddOneSample(const co2_device_data *device_data, const Options *options, Row *row) {
  int result = 0;
  switch (device_data->tag) {
  case CO2:
    result = AddOneCO2(device_data, options, row);
    break;
  case TEMP:
    result = AddOneTemp(device_data, options, row);
    break;
  case HUMIDITY:
    result = AddOneHumidity(device_data, options, row);
    break;
  default:
    break;
  }
  return result;
}

int main(int argc, char * argv[]) {
  int exitCode = 0;
  Options options = { .isShowingCO2 = true,
    .isShowingFahrenheit = true,
    .isShowingHumidity = false,
    .isShowingTemp = false,
    .isVerbose = false,
    .showingTime = ShowingTimeLocal,
    .rowMax = 10,
  };
  exitCode = ParseOptions(argc, argv, &options);
  if (0 != exitCode) {
    return exitCode;
  }
//  argc -= optind;
//  argv += optind;
  hid_init();
  struct hid_device_info *info = co2_enumerate();
  if (info) {
    for (struct hid_device_info *i = info; i; i = i->next) {
      co2_device *device = co2_open_device_path(i->path);
      if (device) {
        int rowCount = 0;
        Row row;
        ReinitRow(&row);
        while (rowCount < options.rowMax) {
          co2_device_data device_data = co2_read_data(device);
          if (0 == device_data.tag && 0 == device_data.value && ! device_data.valid ) {
            fprintf(stderr, "device vanished\n");
            exitCode = 1;
            break;
          } else if (device_data.valid) {
            rowCount += AddOneSample(&device_data, &options, &row);
          }
        }
        co2_close(device);
      } else {
        fprintf(stderr, "device not found or in use by another program.\n");
        exitCode = 1;
      }
    }
    co2_free_enumeration(info);
  } else {
    fprintf(stderr, "device not found\n");
    exitCode = 1;
  }
  hid_exit();
  return exitCode;
}

# SmartCalm — Firmware (ESP32-S3)

![Arduino](https://img.shields.io/badge/Arduino-ESP32--S3-teal) ![C++](https://img.shields.io/badge/C++-firmware-blue)

Firmware for the SmartCalm wearable wristband. Reads physiological signals from onboard sensors, packages them as JSON, and streams them over WiFi to the SmartCalm backend API for real-time stress prediction.

## Features

- Reads 4 physiological signal types every 250ms: EDA (electrodermal activity), BVP (blood volume pulse), skin temperature, and 3-axis acceleration
- Sends readings to the backend over HTTPS as JSON
- Parses the backend's live stress prediction response and prints it to serial
- Auto-reconnects WiFi if the connection drops
- Config-driven — WiFi and API settings are kept out of the source file (see Configuration below)

## Hardware Components

| Sensor | Signal | Interface |
|---|---|---|
| MAX30105 | BVP (blood volume pulse) | I2C |
| MLX90614 | Skin temperature | I2C |
| MPU6050 | 3-axis acceleration | I2C |
| GSR sensor | EDA (electrodermal activity) | Analog (ADC) |

## How It Works

1. On boot, connect to WiFi and initialize all three I2C sensors (MAX30105, MLX90614, MPU6050).
2. Every 250ms, read all sensors: acceleration (x/y/z), BVP, EDA, and skin temperature.
3. Package the readings plus a timestamp, device ID, and user ID into a JSON payload.
4. POST the payload to the backend's `/predict` endpoint over HTTPS.
5. Parse the response — once the backend has buffered enough readings (60), it returns a live stress level and confidence score, printed to serial.

## Configuration

WiFi credentials, the API endpoint, and device/user IDs are **not** hardcoded in the sketch. Instead:

1. Copy `config.h.example` to `config.h`
2. Fill in your real values:
   ```cpp
   #define WIFI_SSID     "your_wifi_ssid"
   #define WIFI_PASSWORD "your_wifi_password"
   #define API_URL       "https://your-api-url.onrender.com/predict"
   #define DEVICE_ID     "esp32-001"
   #define USER_ID       "your-user-uuid"
   ```
3. `config.h` is kept only on your local machine and is never uploaded to GitHub — only `config.h.example` (with placeholder values) is tracked in this repo.

This means switching networks, devices, or backend URLs is just a local `config.h` edit — no changes to the sketch itself.

## Requirements

**Libraries** (install via Arduino Library Manager):
- WiFi, WiFiClientSecure, HTTPClient (bundled with ESP32 board package)
- Wire
- MAX30105 (SparkFun)
- Adafruit MLX90614
- MPU6050_light
- ArduinoJson

**Board:** ESP32-S3 (any variant with sufficient GPIO for I2C + 1 analog input)

## How to Flash

1. Install the ESP32 board package in the Arduino IDE.
2. Install the libraries listed above.
3. Set up `config.h` as described in Configuration.
4. Select your ESP32-S3 board and port, then upload.
5. Open the Serial Monitor at 115200 baud to watch live sensor readings and stress predictions.

## Future Improvements

- Move HTTP timeout and sampling interval into `config.h` as well
- Add local buffering so readings aren't lost if WiFi briefly drops
- Add battery-level reporting

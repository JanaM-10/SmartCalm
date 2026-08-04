#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include "config.h"
#include <Wire.h>
#include "MAX30105.h"
#include <Adafruit_MLX90614.h>
#include <MPU6050_light.h>
#include <ArduinoJson.h>


// ── Pin definitions ───────────────────────────────
#define SDA_PIN  4    // D4
#define SCL_PIN  5    // D5
#define GSR_PIN  A0   // D0 analog

// ── Sensor objects ────────────────────────────────
MAX30105       particleSensor;
Adafruit_MLX90614 mlx;
MPU6050        mpu(Wire);

// ── Timing ────────────────────────────────────────
unsigned long lastSend = 0;
const unsigned long INTERVAL_MS = 250;

// ── WiFiClientSecure ──────────────────────────────
WiFiClientSecure client;

// ─────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== SmartCalm ESP32-S3 ===");

  // I2C with custom pins
  Wire.begin();

  analogReadResolution(12);  // add this

  // Connect WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 40) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("\n❌ WiFi FAILED! Check credentials.");
    while (true) delay(1000);
  }
  Serial.println("\n✅ WiFi Connected! IP: " + WiFi.localIP().toString());

  // Skip SSL certificate verification (fine for testing)
  client.setInsecure();

  // Init MPU6050
  byte mpuStatus = mpu.begin();
  if (mpuStatus != 0) {
    Serial.println("❌ MPU6050 error: " + String(mpuStatus));
  } else {
    Serial.println("Calibrating MPU6050, keep still...");
    mpu.calcOffsets();
    Serial.println("✅ MPU6050 ready.");
  }

  // Init MAX30105
  if (!particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    Serial.println("❌ MAX30105 not found!");
  } else {
    particleSensor.setup();
    Serial.println("✅ MAX30105 ready.");
  }

  // Init MLX90614
  if (!mlx.begin()) {
    Serial.println("❌ MLX90614 not found!");
  } else {
    Serial.println("✅ MLX90614 ready.");
  }

  Serial.println("\n Starting data collection...\n");
}

// ─────────────────────────────────────────────────
void loop() {
  unsigned long now = millis();
  if (now - lastSend >= INTERVAL_MS) {
    lastSend = now;
    sendReading();
  }
}

// ─────────────────────────────────────────────────
void sendReading() {
  // ── Read sensors ────────────────────────────────
  mpu.update();
  float acc_x = mpu.getAccX() *64.0;
  float acc_y = mpu.getAccY() *64.0;
  float acc_z = mpu.getAccZ() *64.0;

  long  irValue  = particleSensor.getIR();
  float bvp      = irValue / 100000.0;

  int   gsrRaw   = analogRead(GSR_PIN);
  float eda      = (gsrRaw / 4095.0 * 3.3) *0.15;

  float skinTemp = mlx.readObjectTempC();

  // ── Build timestamp ──────────────────────────────
  char timestamp[30];
  unsigned long t = millis();
  snprintf(timestamp, sizeof(timestamp), "2025-06-01T%02d:%02d:%02d",
           (int)(t / 3600000) % 24,
           (int)(t / 60000)   % 60,
           (int)(t / 1000)    % 60);

  // ── Build JSON ───────────────────────────────────
  StaticJsonDocument<256> doc;
  doc["device_id"] = DEVICE_ID;
  doc["user_id"]   = USER_ID;
  doc["timestamp"] = timestamp;
  doc["bvp"]       = bvp;
  doc["eda"]       = eda;
  doc["temp"]      = skinTemp;
  doc["acc_x"]     = acc_x;
  doc["acc_y"]     = acc_y;
  doc["acc_z"]     = acc_z;

  String jsonBody;
  serializeJson(doc, jsonBody);

  // ── Debug print ──────────────────────────────────
  Serial.printf("📡 Sending → BVP=%.3f EDA=%.3f TEMP=%.1f ACC=(%.2f,%.2f,%.2f)\n",
                bvp, eda, skinTemp, acc_x, acc_y, acc_z);

  // ── Send HTTP POST ───────────────────────────────
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(client, API_URL);
    http.setTimeout(60000);
    http.addHeader("Content-Type", "application/json");

    int httpCode = http.POST(jsonBody);

    if (httpCode == 200) {
      String response = http.getString();
      StaticJsonDocument<512> res;
      DeserializationError err = deserializeJson(res, response);
      if (!err) {
        const char* stressLevel = res["stress_level"];
        float confidence        = res["confidence"];
        bool  ready             = res["ready"];
        int   windowSize        = res["window_size"];
        if (ready) {
          Serial.printf("✅ Stress: %s (%.0f%% confidence)\n", stressLevel, confidence * 100);
        } else {
          Serial.printf(" Buffering... %d/60 readings\n", windowSize);
        }
      }
    } else if (httpCode == -1) {
      Serial.println("❌ Connection failed - API might be sleeping, retrying...");
    } else {
      Serial.printf("⚠️ HTTP error: %d\n", httpCode);
    }
    http.end();
  } else {
    Serial.println("⚠️ WiFi disconnected, reconnecting...");
    WiFi.reconnect();
  }
}

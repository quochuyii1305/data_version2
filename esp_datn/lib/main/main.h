#pragma once
#include <Arduino.h>
#include <Wire.h>
#include "ads_1115.h"
#include "mqtt_manager.h"
#include "wifi_manager.h"
#include "hrv.h"
#include "pan_tompskins.h"
#include "moving_average.h"
// Cấu hình 250Hz: Gom 25 mẫu gửi 1 lần (tương đương 10 lần/giây)
#define BATCH_SIZE 25 

struct EcgBatch {
    float ecg[BATCH_SIZE];
    float hr;
    float sdnn;
    float rmssd;
    float ibi;
};
#pragma once
#include <WiFiClientSecure.h>
#include <PubSubClient.h>

void setup_mqtt();
void mqtt_loop();
void mqtt_publish_batch(float* ecg_array, int size, float hr, float sdnn, float rmssd, float ibi);
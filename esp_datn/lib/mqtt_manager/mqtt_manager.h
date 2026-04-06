#ifndef MQTT_MANAGER_H
#define MQTT_MANAGER_H

#include <Arduino.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>

void setup_mqtt();
void mqtt_loop();
void mqtt_publish_data(float ecg_val, float hr);
#endif
#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <Arduino.h>
#include <WiFi.h>

void setup_wifi();
void reset_wifi_config();
void handle_wifi_reset_button();

#endif
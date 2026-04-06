#ifndef ADS1115_H
#define ADS1115_H

#include<Wire.h>
#include<stdio.h>

#define ADD_ADS 0x48
#define CHANEL_A0 0
#define CHANEL_A1 1
#define CHANEL_A2 2
#define CHANEL_A3 3

void ads_write(uint8_t reg, uint16_t data);
void ads_read(uint8_t reg, uint8_t* buffer, uint8_t len);
void ads_init();
int16_t ads_read_raw(uint8_t channel);
float ads_read_voltage(uint8_t channel);


#endif
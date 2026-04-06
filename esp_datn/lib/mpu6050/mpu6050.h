#include<stdio.h>
#include<Wire.h>
#include<math.h>


#ifndef MPU6050_H
#define MPU6050_H

#define MPU_ADD 0x68

extern float ax,ay,az, M;

void MPU_write(uint8_t reg, uint8_t data);
void MPU_Read(uint8_t reg, uint8_t *buffer, uint8_t len);
void MPU_init();
void MPU_read_accel(void);

#endif
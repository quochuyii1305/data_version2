#include<mpu6050.h>


int16_t ax_raw = 0, ay_raw = 0, az_raw = 0;
float ax,ay,az, M;

void MPU_write(uint8_t reg, uint8_t data){
    Wire.beginTransmission(MPU_ADD);
    Wire.write(reg);
    Wire.write(data);
    Wire.endTransmission();
}

// doc
void MPU_Read(uint8_t reg, uint8_t *buffer, uint8_t len){
    Wire.beginTransmission(MPU_ADD);
    Wire.write(reg);
    Wire.endTransmission(false);
    Wire.requestFrom((uint8_t)MPU_ADD,(uint8_t)len);
    for (int i = 0; i < len; i++)
    {
        if(Wire.available()){
            buffer[i] = Wire.read();
        }
    }
    
}

void MPU_init(){
    Wire.begin(8,9);
    // wake up
    MPU_write(0x6B,0x00);

    // Accel +- 2g
    MPU_write(0x1C,0x00);
}

// read accel
void MPU_read_accel(void){
    uint8_t data[6];
    MPU_Read(0x3B,data,6);
    ax_raw = (int16_t)(data[0] << 8) | data[1];
    ay_raw = (int16_t)(data[2] << 8) | data[3];
    az_raw = (int16_t)(data[4] << 8) | data[5];

    ax = (ax_raw/16384.0)*9.81; // m/s^2
    ay = (ay_raw/16384.0)*9.81;
    az = (az_raw/16384.0)*9.81;

    M = sqrt(ax*ax + ay*ay + az*az) - 9.81;
}
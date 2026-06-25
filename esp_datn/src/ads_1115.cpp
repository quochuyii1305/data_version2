#include "ads_1115.h"

volatile bool ads_data_ready_flag = false;

void ads_write(uint8_t reg, uint16_t data) {
    Wire.beginTransmission(ADD_ADS);
    Wire.write(reg);
    Wire.write((data >> 8) & 0xFF);
    Wire.write(data & 0xFF);
    Wire.endTransmission();
}

void ads_read(uint8_t reg, uint8_t* buffer, uint8_t len) {
    Wire.beginTransmission(ADD_ADS);
    Wire.write(reg);
    Wire.endTransmission(false);
    Wire.requestFrom((uint8_t)ADD_ADS, (uint8_t)len);
    for (int i = 0; i < len; i++) {
        if (Wire.available()) buffer[i] = Wire.read();
    }
}

// ISR chạy khi DRDY chuyển từ HIGH xuống LOW, báo có data mới
void IRAM_ATTR ads_drdy_isr() {
    ads_data_ready_flag = true;
}

void ads_init_continuous(uint8_t channel) {
    Wire.begin(8, 9);
    Wire.setClock(400000);

    uint16_t config = 0;

    // chọn kênh đo
    switch (channel) {
        case CHANEL_A0: config |= 0b100 << 12; break;
        case CHANEL_A1: config |= 0b101 << 12; break;
        case CHANEL_A2: config |= 0b110 << 12; break;
        case CHANEL_A3: config |= 0b111 << 12; break;
    }

    config |= 0b001 << 9; // PGA +-4.096V
    // bit 8 = 0 nghia la continuous mode
    config |= 0b101 << 5; // 250 SPS
    config |= 0b00;       // COMP_QUE: assert sau 1 conversion

    ads_write(0x01, config);
    ads_write(0x02, 0x0000); // Lo_thresh
    ads_write(0x03, 0x8000); // Hi_thresh

    pinMode(DRDY_PIN, INPUT);
    attachInterrupt(digitalPinToInterrupt(DRDY_PIN), ads_drdy_isr, FALLING);

    Serial.println("[ADS] Continuous 250SPS + interrupt GPIO5 enabled");
}

float ads_read_voltage_continuous() {
    uint8_t data[2];
    ads_read(0x00, data, 2);
    int16_t raw = (int16_t)((data[0] << 8) | data[1]);
    return raw * 4.096f / 32767.0f; // volt
}
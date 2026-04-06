// #include<ads_1115.h>

// void ads_write(uint8_t reg, uint16_t data){
//     Wire.beginTransmission(ADD_ADS);
//     Wire.write(reg);
//     Wire.write((data >> 8) & 0xFF); // MSB
//     Wire.write((data & 0xFF)); // LSB
//     Wire.endTransmission();
// }
// void ads_read(uint8_t reg, uint8_t* buffer, uint8_t len){
//     Wire.beginTransmission(ADD_ADS);
//     Wire.write(reg);
//     Wire.endTransmission(false);

//     Wire.requestFrom((uint8_t)ADD_ADS,(uint8_t)len);

//     for (int i = 0; i < len; i++)
//     {
//         if(Wire.available()){
//             buffer[i] = Wire.read();
//         }
//     }
    
// }

// void ads_init(){
//     Wire.begin(8,9);
// }

// // doc raw adc

// int16_t ads_read_raw(uint8_t channel){
//     uint16_t config = 0;

//     config |= (1 << 15);

//     switch (channel)
//     {
//     case CHANEL_A0:
//         config |= (0b100 << 12);
//         break;
//     case CHANEL_A1:
//         config |= (0b101 << 12);
//         break;
//     case CHANEL_A2:
//         config |= (0b110 << 12);
//         break;
//     case CHANEL_A3:
//         config |= (0b111 << 12);
//         break;
//     }

//     config |= (0b001 << 9); // ±4.096V
//     config |= (0b1 << 8);   // single-shot
//     config |= (0b111 << 5); 
//     config |= (0b11);

//     ads_write(0x01,config);

//     delayMicroseconds(1200);
//     uint8_t data[2];
//     ads_read(0x00,data,2);

//     int16_t raw = (data[0] << 8) | data[1];

//     return raw; 
// }

// float ads_read_voltage(uint8_t channel){
//     int16_t raw = ads_read_raw(channel);
//     return raw * 0.000125038148; 
// }



#include<ads_1115.h>


void ads_write(uint8_t reg, uint16_t data){
    Wire.beginTransmission(ADD_ADS);
    Wire.write(reg);
    // msb of data
    Wire.write((data >> 8)& 0xFF );
    Wire.write(data & 0xFF); // lsb
    Wire.endTransmission();
}
// ham doc 
void ads_read(uint8_t reg, uint8_t* buffer, uint8_t len){
    Wire.beginTransmission(ADD_ADS);
    Wire.write(reg);
    Wire.endTransmission(false);
    Wire.requestFrom((uint8_t)ADD_ADS,(uint8_t)len);
    for(int i = 0; i < len; i++){
        if(Wire.available()){
            buffer[i] = Wire.read();
        }
    }
    
}

void ads_init(){
    Wire.begin(8,9);
}

int16_t ads_read_raw(uint8_t channel){
    uint16_t config = 0;
    // bit 15
    config  |= 1 << 15;
    
// bit 14:12 mux chon kenh

    switch (channel)
    {
    case CHANEL_A0 : 
        config |= 0b100 << 12; 
        break;
    case CHANEL_A1:
        config |= 0b101 << 12;
        break;
    case CHANEL_A2:
        config |= 0b110 << 12;
        break;
    case CHANEL_A3:
        config |= 0b111 << 12;
        break;
    default:
        break;
    }

    // bit 11:9, set up 4.096V
    config |= 0b001 << 9;
    // bit 8: single-shot mode
    config |= 0b1 << 8;
    // bit 7:5 data rate
    config |= 0b100 << 5;
    // bit 4:2
    config |= 0b111 << 2;
    // bit 1:0 comp_que
    config |= 0b11;

    ads_write(0b01,config);
    delayMicroseconds(1200);
    uint8_t data[2];
    ads_read(0b00,data,2);
    uint16_t raw = (data[0] << 8 | data[1]);
    
    return raw;

}

float ads_read_voltage(uint8_t channel){
    int16_t raw = ads_read_raw(channel);
    return raw*4096.0/32767.0;
}
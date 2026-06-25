#pragma once
#include <Arduino.h>

#define HRV_WINDOW 1000 // giữ tối đa khoảng 1000 RR gần nhất để tính
#define HRV_MIN_RR_COUNT 300 // giả sử có 60 nhịp 1 phút, muốn 5phút mới đo thì phải có ít nhất 300 RR

class HRVCalculator {
public:
    HRVCalculator();

    void addRR(float rr_ms);
    void calculate();

    float getSDNN()  { return _sdnn;  }
    float getRMSSD() { return _rmssd; }
    bool  isReady()  { return _count >= HRV_MIN_RR_COUNT; }
    int   getCount() { return _count; }

private:
    float _rr_buf[HRV_WINDOW] = {0};
    int   _count = 0;
    int   _idx   = 0;

    float _sdnn  = 0;
    float _rmssd = 0;
};
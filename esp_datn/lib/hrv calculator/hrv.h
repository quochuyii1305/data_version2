#pragma once
#include <Arduino.h>

#define HRV_WINDOW 600 
#define HRV_MIN_RR_COUNT 300

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
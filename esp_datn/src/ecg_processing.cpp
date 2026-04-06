#include <Arduino.h>
#include "ecg_processing.h"

#define MAX_WINDOW 150

// buffer MA
float ecg_buffer[MAX_WINDOW];
int buffer_index = 0;

// R-peak
float max_val = 0;
float threshold = 0;

// HR
unsigned long last_peak_time = 0;

// ================= MOVING AVERAGE =================
float moving_average(float sample, int N)
{
    ecg_buffer[buffer_index++] = sample;
    if (buffer_index >= N)
        buffer_index = 0;

    float sum = 0;
    for (int i = 0; i < N; i++)
    {
        sum += ecg_buffer[i];
    }
    return sum / N;
}

// ================= R-PEAK =================
bool detect_r_peak(float signal)
{
    if (signal > max_val)
        max_val = signal;

    threshold = 0.7 * max_val;

    if (signal >= threshold)
    {
        return true;
    }
    return false;
}

// ================= MAIN PROCESS =================
float ecg_process(float input, float motion, float *heart_rate)
{
    // chuẩn hóa motion
    float M_norm = constrain(abs(motion) / 2.0, 0, 1);

    // window động
    int N = 5 + (int)(145 * M_norm);

    // lọc
    float filtered = moving_average(input, N);

    // detect R-peak
    if (detect_r_peak(filtered))
    {
        unsigned long now = millis();
        unsigned long RR = now - last_peak_time;

        if (RR > 300 && RR < 2000)
        {
            *heart_rate = 60000.0 / RR;
            last_peak_time = now;
        }
    }

    return filtered;
}
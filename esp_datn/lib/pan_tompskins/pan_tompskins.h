#ifndef PAN_TOMPKINS_H
#define PAN_TOMPKINS_H

#include <Arduino.h>

#define SAMPLE_RATE_HZ 250
#define MWI_SIZE 38          // ~ 150ms chiều rộng cửa sổ phải xấp xỉ bằng với chiều rộng của phức bộ QRS rộng nhất có thể xảy ra
#define REFRACTORY_PERIOD 50 // khoảng thời gian trễ 200 ms

#define IIR_TAPS 5
#define DERIVATIVE_TAPS 5

struct ECG_Signals
{
    float lpf_out;      // Sóng sau lọc thông thấp
    float hpf_out;      // Sóng sau lọc thông cao
    float derivative;   // Sóng sau đạo hàm
    float squared;      // Sóng sau bình phương
    float mwi_out;      // Sóng sau tích phân cửa sổ
    float threshold_i1; // ngưỡng động cao cho mwi
    float threshold_i2; // ngưỡng động thấp cho mwi
    float threshold_f1; // ngưỡng động cao cho mwi
    float threshold_f2; // ngưỡng động thấp cho hpf
};

class PanTompkinsECG
{
private:
    // trạng thái bộ lọc Butterworth
    float x_LP[IIR_TAPS];
    float y_LP[IIR_TAPS];

    float x_HP[IIR_TAPS];
    float y_HP[IIR_TAPS];

    float x_der[DERIVATIVE_TAPS];

    // Trạng thái MWI
    float mwi_buffer[MWI_SIZE];
    int mwi_index;
    float mwi_sum;

    // kênh I - threshold
    float threshold_i1, threshold_i2;
    float spki, npki;

    // Kênh F - threshold
    float threshold_f1, threshold_f2;
    float spkf, npkf;

    // Local peak detection - kênh I
    float prev_mwi, prev_prev_mwi;

    // Local peak detection - kênh F
    float prev_f, prev_prev_f;

    // Timing & RR
    int time_since_last_r_peak;
    // RR average circular buffer
    float rr_buffer[8];
    int rr_buf_index;
    int rr_buf_count; // đếm số nhịp đã có, tối đa 8

    // Khởi tạo
    bool initialized;
    float init_max_i;
    float init_max_f;

    // Các hàm xử lý nội bộ
    float lowPassFilter(float new_sample);
    float highPassFilter(float new_sample);
    void updateThresholds();
    float getRRAverage();

public:
    PanTompkinsECG();
    int process(float adc_value, ECG_Signals &signals, float &rr_out);
};

#endif
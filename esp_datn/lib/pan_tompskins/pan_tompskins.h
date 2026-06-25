#ifndef PAN_TOMPKINS_H
#define PAN_TOMPKINS_H

#include <Arduino.h>

#define SAMPLE_RATE_HZ      250
#define MWI_SIZE            38 // ứng với 150ms để gom đủ năng lượng vùng qrs
#define REFRACTORY_PERIOD   50

#define IIR_TAPS            5
#define DERIVATIVE_TAPS     5

struct ECG_Signals {
    float lpf_out;      // Sóng sau lọc thông thấp
    float hpf_out;      // Sóng sau lọc thông cao
    float derivative;   // Sóng sau đạo hàm
    float squared;      // Sóng sau bình phương
    float mwi_out;      // Sóng sau tích phân cửa sổ
    float threshold_i1; // Ngưỡng động hiện tại
};

class PanTompkinsECG {
private:
    // Trạng thái bộ lọc Butterworth bậc 8
    float x_LP[IIR_TAPS];
    float y_LP[IIR_TAPS];

    float x_HP[IIR_TAPS];
    float y_HP[IIR_TAPS];

    // Trạng thái đạo hàm FIR 9 điểm
    float x_der[DERIVATIVE_TAPS];

    // Trạng thái MWI
    float mwi_buffer[MWI_SIZE];
    int mwi_index;
    float mwi_sum;

    // Trạng thái bắt đỉnh & BPM
    float threshold_i1;
    float noise_i1;
    float signal_peak;
    float noise_peak;
    int time_since_last_r_peak;

    // Các hàm xử lý nội bộ
    float lowPassFilter(float new_sample);
    float highPassFilter(float new_sample);

public:
    PanTompkinsECG();

    int process(float adc_value, ECG_Signals &signals, float &rr_out);
};

#endif
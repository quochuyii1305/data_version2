#include "pan_tompskins.h"

// [HPF] fc = 5Hz - Butterworth bậc 4
static const float HPF_B[IIR_TAPS] = {
    0.84847530f,
    -3.39390118f,
    5.09085177f,
    -3.39390118f,
    0.84847530f};

static const float HPF_A[IIR_TAPS] = {
    1.00000000f,
    -3.67172909f,
    5.06799839f,
    -3.11596693f,
    0.71991033f};

// [LPF] fc = 11Hz - Butterworth bậc 4
static const float LPF_B[IIR_TAPS] = {
    0.00026065f,
    0.00104261f,
    0.00156391f,
    0.00104261f,
    0.00026065f};

static const float LPF_A[IIR_TAPS] = {
    1.00000000f,
    -3.27865806f,
    4.08491089f,
    -2.28633875f,
    0.48425635f};

    // constructor
PanTompkinsECG::PanTompkinsECG()
{
   
    for (int i = 0; i < IIR_TAPS; i++)
    {
        x_LP[i] = 0.0f;
        y_LP[i] = 0.0f;

        x_HP[i] = 0.0f;
        y_HP[i] = 0.0f;
    }

    // Init đạo hàm FIR 5 điểm
    for (int i = 0; i < DERIVATIVE_TAPS; i++)
    {
        x_der[i] = 0.0f;
    }

    // Init MWI
    for (int i = 0; i < MWI_SIZE; i++)
    {
        mwi_buffer[i] = 0.0f;
    }

    mwi_index = 0;
    mwi_sum = 0.0f;

    threshold_i1 = 0.0f;
    noise_i1 = 0.0f;
    signal_peak = 0.0f;
    noise_peak = 0.0f;

    time_since_last_r_peak = 0;
}

static inline float applyIIR8(
    float x_new,
    float x[],
    float y[],
    const float b[],
    const float a[])
{
    // Dịch buffer
    for (int i = IIR_TAPS - 1; i > 0; i--)
    {
        x[i] = x[i - 1];
        y[i] = y[i - 1];
    }

    x[0] = x_new;

    double result = 0.0;

    for (int i = 0; i < IIR_TAPS; i++)
    {
        result += (double)b[i] * (double)x[i];
    }

    for (int i = 1; i < IIR_TAPS; i++)
    {
        result -= (double)a[i] * (double)y[i];
    }

    y[0] = (float)result;
    return y[0];
}

float PanTompkinsECG::lowPassFilter(float new_sample)
{
    return applyIIR8(new_sample, x_LP, y_LP, LPF_B, LPF_A);
}

float PanTompkinsECG::highPassFilter(float new_sample)
{
    return applyIIR8(new_sample, x_HP, y_HP, HPF_B, HPF_A);
}

int PanTompkinsECG::process(float adc_value, ECG_Signals &signals, float &rr_out)
{
    time_since_last_r_peak++; // số mẫu đọc được từ ads1115

    int current_bpm = 0;
    rr_out = 0.0f;

    signals.lpf_out = lowPassFilter(adc_value);
    signals.hpf_out = highPassFilter(signals.lpf_out);

   // đạo hàm 5 điểm
    for (int i = DERIVATIVE_TAPS - 1; i > 0; i--)
    {
        x_der[i] = x_der[i - 1];
    }

    x_der[0] = signals.hpf_out;

    signals.derivative =
        ((1.0f * x_der[0] + 2.0f * x_der[1] - 2.0f * x_der[3] - 1.0f * x_der[4])) * 12.5 / 8.0f;

    // 3. Bình phương
    signals.squared = signals.derivative * signals.derivative;

    // 4. MWI - tích phân cửa sổ động
    mwi_sum -= mwi_buffer[mwi_index];

    mwi_buffer[mwi_index] = signals.squared;

    mwi_sum += mwi_buffer[mwi_index];

    if (++mwi_index >= MWI_SIZE)
    {
        mwi_index = 0;
    }

    signals.mwi_out = mwi_sum / MWI_SIZE;
    signals.threshold_i1 = threshold_i1;

    // 5. Phát hiện đỉnh, tính RR và BPM
    if (signals.mwi_out > threshold_i1 &&
        time_since_last_r_peak > REFRACTORY_PERIOD) // phải đọc ít nhất 50 mẫu mới tìm đỉnh
    {

        signal_peak = 0.125f * signals.mwi_out + 0.875f * signal_peak;

        threshold_i1 = noise_i1 + 0.25f * (signal_peak - noise_i1);

        float temp_rr =
            (float)time_since_last_r_peak * (1000.0f / SAMPLE_RATE_HZ);

        int temp_bpm =
            (60 * SAMPLE_RATE_HZ) / time_since_last_r_peak;

        // Chỉ chấp nhận RR trong khoảng 300-1500 ms
        // Tương đương 40-200 BPM
        if (temp_rr > 300.0f && temp_rr < 1500.0f)
        {
            rr_out = temp_rr;
            current_bpm = temp_bpm;
        }

        time_since_last_r_peak = 0;
    }
    else if (signals.mwi_out > threshold_i1 * 0.5f)
    {
        noise_peak = 0.125f * signals.mwi_out + 0.875f * noise_peak;
        noise_i1 = noise_peak;
        threshold_i1 = noise_i1 + 0.25f * (signal_peak - noise_i1);
    }

    signals.threshold_i1 = threshold_i1;

    return current_bpm;
}
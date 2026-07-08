#include "pan_tompskins.h"

// HPF fc = 5Hz - Butterworth bậc 4
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

// LPF fc = 11Hz - Butterworth bậc 4
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

    // Init đạo hàm
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

    threshold_i1 = spki = npki = threshold_i2 = 0.0f;
    threshold_f1 = spkf = npkf = threshold_f2 = 0.0f;

    prev_mwi = prev_prev_mwi = 0.0f;
    prev_f = prev_prev_f = 0.0f;

    time_since_last_r_peak = 0;

    for (int i = 0; i < 8; i++)
        rr_buffer[i] = 0.0f;
    rr_buf_index = 0;
    rr_buf_count = 0;

    initialized = false;
    init_max_i = 0.0f;
    init_max_f = 0.0f;

    sb_peak_i_val = 0.0f;
    sb_peak_f_val = 0.0f;
    sb_time_since_r_peak = 0;
    peak_f_val = 0.0f;

    for (int i = 0; i < F_SEARCH_WINDOW; i++)
    {
        f_buffer[i] = 0.0f;
    }
    f_index = 0;
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

// Helper: detect local maximum tại sample trước
// prev_prev < prev > current
static inline bool isLocalMax(float pp, float p, float cur)
{
    return (p > pp && p > cur && p > 0.0f);
}

// tính RR trung bình
float PanTompkinsECG::getRRAverage()
{
    if (rr_buf_count == 0)
        return 0.0f;
    float sum = 0.0f;
    for (int i = 0; i < rr_buf_count; i++)
        sum += rr_buffer[i];
    return sum / rr_buf_count;
}

// lay gia tri hpf max trong 200ms truoc
float PanTompkinsECG::getMaxFWindow()
{
    float max_val = 0;
    for (int i = 0; i < F_SEARCH_WINDOW; i++)
    {
        if (f_buffer[i] > max_val)
        {
            max_val = f_buffer[i];
        }
    }
    return max_val;
}

// cap nhat nguong cao và ngưỡng thấp
void PanTompkinsECG::updateThresholds()
{
    threshold_i1 = npki + 0.25f * (spki - npki);
    threshold_i2 = 0.5f * threshold_i1;

    threshold_f1 = npkf + 0.25f * (spkf - npkf);
    threshold_f2 = 0.5f * threshold_f1;
}

int PanTompkinsECG::process(float adc_value, ECG_Signals &signals, float &rr_out)
{
    // mỗi lần có 1 mẫu thì time_since lên + 1
    time_since_last_r_peak++;
    rr_out = 0.0f;
    int current_bpm = 0;

    // 1. Bandpass kênh f
    signals.lpf_out = lowPassFilter(adc_value);
    signals.hpf_out = highPassFilter(signals.lpf_out); // đây là kênh F

    // 2. Đạo hàm 5 điểm
    for (int i = DERIVATIVE_TAPS - 1; i > 0; i--)
        x_der[i] = x_der[i - 1];
    x_der[0] = signals.hpf_out;
    signals.derivative =
        (x_der[0] + 2.0f * x_der[1] - 2.0f * x_der[3] - x_der[4]) * (SAMPLE_RATE_HZ / 8.0f);

    // 3. Bình phương
    signals.squared = signals.derivative * signals.derivative;

    // 4. MWI kênh I
    mwi_sum -= mwi_buffer[mwi_index];

    mwi_buffer[mwi_index] = signals.squared;
    mwi_sum += signals.squared;
    if (++mwi_index >= MWI_SIZE)
        mwi_index = 0;
    signals.mwi_out = mwi_sum / MWI_SIZE;

    // 5. Khởi tạo threshold lần đầu (sau 2 giây)
    if (!initialized)
    {
        if (signals.mwi_out > init_max_i)
            init_max_i = signals.mwi_out;
        float f_abs = fabsf(signals.hpf_out);
        if (f_abs > init_max_f)
            init_max_f = f_abs;
        if (time_since_last_r_peak >= 2 * SAMPLE_RATE_HZ)
        {
            // Khởi tạo từ max thực đo được trong 2 giây
            spki = init_max_i;
            npki = init_max_i * 0.5f;

            spkf = init_max_f;
            npkf = init_max_f * 0.5f;
            updateThresholds();

            initialized = true;
            time_since_last_r_peak = 0;

            signals.threshold_i1 = threshold_i1;
            signals.threshold_i2 = threshold_i2;
            signals.threshold_f1 = threshold_f1;
            signals.threshold_f2 = threshold_f2;
            return 0;
        }
        return 0;
    }

    // 6. xac dinh max tren kenh F cua hpf
    float f_abs = fabsf(signals.hpf_out);

    f_buffer[f_index++] = f_abs;
    if (f_index >= F_SEARCH_WINDOW)
    {
        f_index = 0;
    }
    // 7. phat hien dinh o kenh I

    bool found_peak_i = false;
    float peak_i_val = 0.0f;
    if (time_since_last_r_peak > REFRACTORY_PERIOD)
    {
        if (isLocalMax(prev_prev_mwi, prev_mwi, signals.mwi_out))
        {
            found_peak_i = true;
            peak_i_val = prev_mwi;
        }
    }
    prev_prev_mwi = prev_mwi;
    prev_mwi = signals.mwi_out;

    // 8 xac nhan qrs
    if (found_peak_i)
    {
        float peak_f_candidate = getMaxFWindow();

        // xem xet dinh I va F cao nhat
        if (peak_i_val > threshold_i1)
        {
            // tim peak F tuong ung voi peakI

            if (peak_f_candidate > threshold_f1)
            {
                // neu la qrs that
                spki = 0.125f * peak_i_val + 0.875f * spki;
                spkf = 0.125f * peak_f_candidate + 0.875f * spkf;

                updateThresholds();

                // tinh nhip tim
                float temp_rr = time_since_last_r_peak * (1000.0f / SAMPLE_RATE_HZ);
                int temp_bpm = 60000 / temp_rr;

                if (temp_rr > 300.0f && temp_rr < 1500.0f)
                {
                    rr_out = temp_rr;
                    current_bpm = temp_bpm;

                    // cap nhat RR trung binh
                    rr_buffer[rr_buf_index] = temp_rr;
                    rr_buf_index = (rr_buf_index + 1) % 8;
                    if (rr_buf_count < 8)
                    {
                        rr_buf_count++;
                    }
                    // Reset bộ đếm và xóa đỉnh lưu trữ
                    time_since_last_r_peak = 0;
                    peak_f_val = 0.0f;
                    sb_peak_i_val = 0.0f;
                    sb_peak_f_val = 0.0f;
                }
            }
            else
            {
                // neu la nhiễu
                npki = 0.125f * peak_i_val + 0.875f * npki;
                npkf = 0.125f * peak_f_candidate + 0.875f * npkf;

                updateThresholds();

                // luu vao search back neu no la dinh cao naht
                if (peak_i_val > threshold_i2 && peak_i_val > sb_peak_i_val)
                {
                    sb_peak_i_val = peak_i_val;
                    sb_peak_f_val = peak_f_candidate;
                    sb_time_since_r_peak = time_since_last_r_peak;
                }
            }
            if (time_since_last_r_peak == REFRACTORY_PERIOD)
            {
                peak_f_val = 0.0f;
            }
        }
        // neu peaki < thresholdi1
        else
        {
            npki = 0.125f * peak_i_val + 0.875f * npki;
            npkf = 0.125f * peak_f_candidate + 0.875f * npkf;
            updateThresholds();

            if (peak_i_val > threshold_i2 && peak_i_val > sb_peak_i_val)
            {
                sb_peak_i_val = peak_i_val;
                sb_peak_f_val = peak_f_candidate;
                sb_time_since_r_peak = time_since_last_r_peak;
            }
        }
    }
    // 9 co che search back
    float rr_avg_ms = getRRAverage();

    // neu rr > 1.66 rr_AVG
    float rr_elapsed_ms = time_since_last_r_peak * 1000.0f / SAMPLE_RATE_HZ;
    if (rr_elapsed_ms > 1.66f * rr_avg_ms &&
        sb_peak_i_val > threshold_i2 &&
        sb_peak_f_val > threshold_f2)
    {
        if (sb_peak_f_val > threshold_f2)
        {
            spki = 0.25f * sb_peak_i_val + 0.75 * spki;
            spkf = 0.25 * sb_peak_f_val + 0.75 * spkf;
            updateThresholds();

            float temp_rr = (float)sb_time_since_r_peak * (1000.0f / SAMPLE_RATE_HZ);
            int temp_bpm = (60 * SAMPLE_RATE_HZ) / sb_time_since_r_peak;

            if (temp_rr > 300.0f && temp_rr < 1500.0f)
            {
                rr_out = temp_rr;
                current_bpm = temp_bpm;

                rr_buffer[rr_buf_index] = temp_rr;
                rr_buf_index = (rr_buf_index + 1) % 8;
                if (rr_buf_count < 8)
                    rr_buf_count++;
            }

            // lui thoi gian ve dung khoang tu ung vien bi sot toi hien tai
            time_since_last_r_peak = time_since_last_r_peak - sb_time_since_r_peak;
            peak_f_val = 0.0f;
            sb_peak_i_val = 0.0f;
            sb_peak_f_val = 0.0f;
        }
    }

    signals.threshold_i1 = threshold_i1;
    signals.threshold_i2 = threshold_i2;
    signals.threshold_f1 = threshold_f1;
    signals.threshold_f2 = threshold_f2;
    return current_bpm;
}
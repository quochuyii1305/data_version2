#include "hrv.h"
#include <math.h>

HRVCalculator::HRVCalculator() {
    memset(_rr_buf, 0, sizeof(_rr_buf));
}

void HRVCalculator::addRR(float rr_ms) {
    if (rr_ms < 300 || rr_ms > 1500) return;

    _rr_buf[_idx] = rr_ms;
    // nếu count = 799 thì thay thằng 0 bằng thằng rr thứ 800
    _idx = (_idx + 1) % HRV_WINDOW;

    if (_count < HRV_WINDOW) {
        _count++;
    }
}

void HRVCalculator::calculate() {
    if (_count < 2) return;

    // ================= SDNN =================
    float sum = 0;
    for (int i = 0; i < _count; i++) {
        sum += _rr_buf[i];
    }

    float mean = sum / _count;

    float variance = 0;
    for (int i = 0; i < _count; i++) {
        float d = _rr_buf[i] - mean;
        variance += d * d;
    }

    _sdnn = sqrt(variance / (_count - 1));

    // ================= RMSSD =================
    float sum_sq = 0;

    int start_idx = (_count == HRV_WINDOW) ? _idx : 0;

    for (int i = 1; i < _count; i++) {
        int curr_idx = (start_idx + i) % HRV_WINDOW;
        int prev_idx = (start_idx + i - 1) % HRV_WINDOW;

        float diff = _rr_buf[curr_idx] - _rr_buf[prev_idx];
        sum_sq += diff * diff;
    }

    _rmssd = sqrt(sum_sq / (_count - 1));
}
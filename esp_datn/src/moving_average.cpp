#include "moving_average.h"

// constructor
MovingAverageFilter::MovingAverageFilter() {
    index = 0;
    sum = 0.0f;
    for (int i = 0; i < MA_WINDOW_SIZE; i++) {
        buffer[i] = 0.0f;
    }
}

float MovingAverageFilter::process(float new_val) {
    // dùng mảng vòng
    // trừ đi giá trị cũ nhất
    sum -= buffer[index];
    // nạp giá trị mới vào mảng
    buffer[index] = new_val;
    // cộng giá trị mới vào tổng
    sum += buffer[index];
    
    // xoay vòng index
    index = (index + 1) % MA_WINDOW_SIZE;
    
    // trả về giá trị trung bình
    return sum / MA_WINDOW_SIZE;
}
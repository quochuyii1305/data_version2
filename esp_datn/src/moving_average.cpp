#include "moving_average.h"

MovingAverageFilter::MovingAverageFilter() {
    index = 0;
    sum = 0.0f;
    for (int i = 0; i < MA_WINDOW_SIZE; i++) {
        buffer[i] = 0.0f;
    }
}

float MovingAverageFilter::process(float new_val) {
    // Trừ đi giá trị cũ nhất
    sum -= buffer[index];
    // Nạp giá trị mới vào mảng
    buffer[index] = new_val;
    // Cộng giá trị mới vào tổng
    sum += buffer[index];
    
    // Xoay vòng index
    index = (index + 1) % MA_WINDOW_SIZE;
    
    // Trả về giá trị trung bình
    return sum / MA_WINDOW_SIZE;
}
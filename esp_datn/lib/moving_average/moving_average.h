#ifndef MOVING_AVERAGE_H
#define MOVING_AVERAGE_H


#define MA_WINDOW_SIZE 10 

class MovingAverageFilter {
private:
    float buffer[MA_WINDOW_SIZE];
    int index;
    float sum;

public:
    MovingAverageFilter();
    float process(float new_val);
};

#endif
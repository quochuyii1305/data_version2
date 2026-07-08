#include "main.h"
float heart_rate = 0;
float ecg_filtered = 0;
float last_rr = 0;

float hrv_sdnn = 0;
float hrv_rmssd = 0;

HRVCalculator hrv;
PanTompkinsECG ecgProcessor;
ECG_Signals current_signals;
MovingAverageFilter maProcessor;

unsigned long prev_hrv = 0;
const long interval_hrv = 5000;

int sample_count = 0;
unsigned long freq_timer = 0;
int mqtt_sample_count = 0;

float current_ecg_batch[BATCH_SIZE];
int batch_index = 0;
float pending_ibi_for_batch = 0.0f;

QueueHandle_t ecg_queue;

void mqtt_task(void *parameter)
{
    EcgBatch batch;
    while (true)
    {
        // chờ dữ liệu từ hàng đợi
        if (xQueueReceive(ecg_queue, &batch, portMAX_DELAY) == pdTRUE)
        {
            mqtt_loop();
            mqtt_publish_batch(batch.ecg, BATCH_SIZE, batch.hr,
                               batch.sdnn, batch.rmssd, batch.ibi);
            mqtt_sample_count += BATCH_SIZE;
        }
    }
}

void setup()
{
    Serial.begin(115200);
    Serial.println();
    Serial.println("===== ESP32 START =====");

    setup_wifi();
    ads_init_continuous(CHANEL_A0);

    setup_mqtt();

    ecg_queue = xQueueCreate(20, sizeof(EcgBatch)); // khởi tạo hàng đợi, tạo ra 1 đường ống chứa tối da 20 gói dữ liệu
                                                    // mỗi gói có cấu trúc là EcgBatch (chứa 25 điểm ECG cùng các chỉ số)
    // tạo 1 luồng xử lý độc lập
    xTaskCreatePinnedToCore(
        mqtt_task,   // hàm thực thi tác vụ
        "MQTT_Task", // tên tác vụ
        16384,        // dung lượng bộ nhớ stack cấp cho task
        NULL,        // tham số truyền vào
        1,           // mức độ ưu tiên
        NULL,        // biến quản lý task
        0            // Chạy gửi MQTT trên Core 0
    );

    freq_timer = millis();
}

void loop()
{
    handle_wifi_reset_button();
    if (ads_data_ready_flag)
    {
        ads_data_ready_flag = false;

        float ecg_raw = ads_read_voltage_continuous();
        // Serial.print("ECG: ");
        // Serial.println(ecg_raw);
        float ecg_ma = maProcessor.process(ecg_raw);

        int bpm = ecgProcessor.process(ecg_raw, current_signals, last_rr);
        // Serial.println(current_signals.lpf_out);

        // Serial.println(current_signals.mwi_out);
        // Serial.println(current_signals.mwi_out);

        // Serial.println(current_signals.mwi_out);
        // Serial.println(bpm);

        // Chỉ cập nhật Heart Rate khi module bắt được đỉnh R (bpm > 0)
        if (bpm > 0)
        {
            heart_rate = bpm;
        }
        // 4. Nếu có RR mới thì đẩy vào tính HRV live
        // đồng thời giữ lại để gửi lên app đúng 1 lần

        if (last_rr > 0)
        {
            // mỗi lần phát hiện đỉnh, cho khoảng cách rr vào mảng
            hrv.addRR(last_rr);
            pending_ibi_for_batch = last_rr; // khoảng cách 2 đỉnh gần nhất
        }

        // 5. Gom tín hiệu ecg_filtered vào mảng để gửi MQTT

        current_ecg_batch[batch_index] = ecg_ma;
        batch_index++;

        if (batch_index >= BATCH_SIZE)
        {
            EcgBatch batch;
            memcpy(batch.ecg, current_ecg_batch, sizeof(current_ecg_batch));
            batch.hr = heart_rate;
            batch.sdnn = hrv_sdnn;
            batch.rmssd = hrv_rmssd;
            batch.ibi = pending_ibi_for_batch;

            pending_ibi_for_batch = 0.0f;

            xQueueSend(ecg_queue, &batch, 0); // đẩy dữ liệu vào hàng đợi
            batch_index = 0;
        }

        sample_count++;
    }

    // if (millis() - freq_timer >= 1000)
    // {
    //     Serial.printf("[FREQ-READ] %d Hz | [FREQ-MQTT] %d mẫu/s | Queue Batch: %d\n",
    //                   sample_count, mqtt_sample_count,
    //                   uxQueueMessagesWaiting(ecg_queue));
    //     sample_count = 0;
    //     mqtt_sample_count = 0;
    //     freq_timer = millis();
    // }

    if (millis() - prev_hrv >= interval_hrv)
    {
        prev_hrv = millis();
        if (hrv.isReady())
        {
            hrv.calculate();
            hrv_sdnn = hrv.getSDNN();
            hrv_rmssd = hrv.getRMSSD();
        }
    }
}

// #include<Arduino.h>

// void setup() {
//   // Khởi tạo cổng Serial với tốc độ baudrate là 115200
//   Serial.begin(115200);
//   delay(1000); // Chờ 1 giây để ổn định cổng Serial

//   Serial.println("--- ESP32 TEST OK ---");
// }

// void loop() {
//   // In ra màn hình dòng chữ Hello World mỗi 1 giây
//   Serial.println("Hello World từ ESP32!");
//   delay(1000);
// }
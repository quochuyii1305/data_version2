#include <main.h>



// ── TIMER ĐỌC CẢM BIẾN: 10ms = 100Hz ─────────────────────────────────────────
// ADS1015 cấu hình 128 SPS nên đọc 100Hz là hợp lý
unsigned long previousMillis_Sensor = 0;
const long    interval_Sensor       = 1;


float heart_rate = 0;
float motion_M = 0;
float ecg_filtered = 0;

// ── TIMER GỬI MQTT: 20ms = 50Hz ───────────────────────────────────────────────
// Flutter dùng 200 điểm hiển thị @ 50Hz = 4 giây sóng cuộn
// Tăng từ 1000ms (1Hz) lên 20ms (50Hz) để sóng vẽ mượt
unsigned long previousMillis_MQTT = 0;
const long    interval_MQTT       = 20;

float current_ecg = 0.0;

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);
  ads_init();
  MPU_init();
  setup_wifi();
  setup_mqtt();
}

void loop() {
  // Duy trì kết nối MQTT
  mqtt_loop();

  unsigned long currentMillis = millis();

  // ── TASK 1: Đọc cảm biến 100Hz ──────────────────────────────────────────────
  if (currentMillis - previousMillis_Sensor >= interval_Sensor) {
    previousMillis_Sensor = currentMillis;

    // Đọc điện áp từ ADS1015 kênh A0 (nối với OUTPUT của AD8232)
    current_ecg = (ads_read_voltage(CHANEL_A0) - 1.65);
    MPU_read_accel();
    motion_M = M;

    ecg_filtered = ecg_process(current_ecg, motion_M, &heart_rate);


    // Debug Serial Plotter
    Serial.print("ECG:");
    Serial.println(ecg_filtered);
    Serial.print("HR:");
    Serial.println(heart_rate);
  }

  // ── TASK 2: Gửi MQTT 50Hz ───────────────────────────────────────────────────
  if (currentMillis - previousMillis_MQTT >= interval_MQTT) {
    previousMillis_MQTT = currentMillis;

    // Gửi giá trị ECG mới nhất lên HiveMQ
    // Flutter nhận và vẽ ngay lập tức
    mqtt_publish_data(current_ecg,heart_rate);
  }
}
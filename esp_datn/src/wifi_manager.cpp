#include "wifi_manager.h"
#include <WiFiManager.h>

#define WIFI_CONFIG_AP_NAME   "ECG_Device_Setup"
#define WIFI_CONFIG_AP_PASS   "12345678"
#define WIFI_RESET_BUTTON_PIN 0
#define HOLD_TIME_MS          3000  
void reset_wifi_config() {
    WiFiManager wm;
    wm.resetSettings();
    Serial.println("Da xoa cau hinh WiFi da luu");

    // phát wifi ra ngoài
    bool connected = wm.startConfigPortal(WIFI_CONFIG_AP_NAME, WIFI_CONFIG_AP_PASS);

    if (connected) {
        Serial.println("Cau hinh WiFi moi thanh cong");
        Serial.print("SSID moi: "); Serial.println(WiFi.SSID());
        Serial.print("IP moi: ");   Serial.println(WiFi.localIP());
    } else {
        Serial.println("Het thoi gian cau hinh WiFi");
    }

    Serial.println("ESP32 se restart...");
    Serial.flush();
    delay(1500);
    ESP.restart();
}

void setup_wifi() {
    pinMode(WIFI_RESET_BUTTON_PIN, INPUT_PULLUP);
    delay(50); 

    Serial.println("Dang khoi tao WiFi...");

    WiFi.mode(WIFI_STA);
    // tự động kết nối wifi cũ
    WiFi.setAutoReconnect(true);
    WiFi.persistent(true);

    WiFiManager wm;
    wm.setConfigPortalTimeout(180);

    bool connected = wm.autoConnect(WIFI_CONFIG_AP_NAME, WIFI_CONFIG_AP_PASS);

    if (!connected) {
        Serial.println("Khong ket noi duoc WiFi, ESP32 se restart...");
        delay(2000);
        ESP.restart();
    }

    Serial.println("Da ket noi WiFi thanh cong!");
    Serial.print("SSID: "); Serial.println(WiFi.SSID());
    Serial.print("IP: ");   Serial.println(WiFi.localIP());
}

// Gọi trong loop() — giữ nút 3 giây sau khi đã boot để reset WiFi
void handle_wifi_reset_button() {
    static unsigned long press_start = 0;
    static bool is_pressed = false;

    if (digitalRead(WIFI_RESET_BUTTON_PIN) == LOW) {
        if (!is_pressed) {
            is_pressed = true;
            press_start = millis();
            Serial.println("Dang giu nut BOOT...");
        } else if (millis() - press_start >= HOLD_TIME_MS) {
            Serial.println("Giu du 3 giay -> Reset WiFi!");
            reset_wifi_config();
        }
    } else {
        if (is_pressed) {
            Serial.println("Tha nut, huy reset");
        }
        is_pressed = false;
        press_start = 0;
    }
}
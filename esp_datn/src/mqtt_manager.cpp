// #include <mqtt_manager.h>

// const char* mqtt_server   = "997d108d7c76499ba4d812a8b07fa63c.s1.eu.hivemq.cloud";
// const int   mqtt_port     = 8883;
// const char* mqtt_username = "quochuyii1305";
// const char* mqtt_password = "Quochuyii1305";

// WiFiClientSecure espClient;
// PubSubClient     client(espClient);

// unsigned long lastReconnectAttempt = 0;

// void setup_mqtt() {
//   espClient.setInsecure();
//   client.setServer(mqtt_server, mqtt_port);
// }

// void mqtt_loop() {
//   if (!client.connected()) {
//     long now = millis();
//     if (now - lastReconnectAttempt > 5000) {
//       lastReconnectAttempt = now;
//       Serial.print("Dang thu ket noi MQTT...");
//       if (client.connect("ESP32Client", mqtt_username, mqtt_password)) {
//         Serial.println("Thanh cong!");
//         lastReconnectAttempt = 0;
//       } else {
//         Serial.print("That bai, rc=");
//         Serial.println(client.state());
//       }
//     }
//   } else {
//     client.loop();
//   }
// }

// // Gửi JSON đúng format Flutter đọc được
// // Flutter parse: EcgPoint.fromJson() → cần {"ecg": 1.23}
// void mqtt_publish_data(float ecg_val,float hr) {
//   if (!client.connected()) return;

//   char payload[32];
//   // Tạo JSON: {"ecg":1.23}
//   // %.4f giữ 4 chữ số thập phân — đủ độ chính xác cho ADS1015
//   snprintf(payload, sizeof(payload), "{\"ecg\":%.4f, \"hr\":%.1f}", ecg_val,hr);

//   client.publish("ecg/data", payload);
// }

#include<mqtt_manager.h>

const char* mqtt_server   = "997d108d7c76499ba4d812a8b07fa63c.s1.eu.hivemq.cloud";
const int   mqtt_port     = 8883;
const char* mqtt_username = "quochuyii1305";
const char* mqtt_password = "Quochuyii1305";

WiFiClientSecure espClient;
PubSubClient client(espClient);

void setup_mqtt(){
  espClient.setInsecure();
  client.setServer(mqtt_server,mqtt_port);

}

void mqtt_loop(){
  if(!client.connected()){
    if(client.connect("ESP32Client_Datn",mqtt_username,mqtt_password)){
      Serial.println("Thanh cong");
    }
    else{
      client.loop();
    }
  }
}

void mqtt_publish_data(float ecg_val, float hr){
  if(!client.connected()) return;
  char payload[64];
  snprintf(payload,sizeof(payload),"{\"ecg\":%.4f, \"hr\":%.1f}", ecg_val,hr);
  client.publish("ecg/data",payload);
}
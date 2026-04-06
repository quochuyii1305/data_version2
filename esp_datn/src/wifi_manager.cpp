

// #include <wifi_manager.h>

// // WiFi config
// const char* ssid = "Trang T4";
// const char* password = "688699688";

// void setup_wifi() {
//   Serial.print("Dang ket noi WiFi...");
//   WiFi.begin(ssid, password);

//   while (WiFi.status() != WL_CONNECTED) {
//     delay(500);
//     Serial.print(".");
//   }

//   Serial.println("\nDa ket noi!");
//   Serial.println(WiFi.localIP());
// }

#include<WiFi.h>

const char* ssid = "Trang T4";
const char* password = "688699688";
// wifi config
void setup_wifi(){
  Serial.print("Dang ket noi WIFI...");
  WiFi.begin(ssid,password);
  while ((WiFi.status() != WL_CONNECTED))
  {
    /* code */
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nDa ket noi");
  Serial.println(WiFi.localIP());
  
}
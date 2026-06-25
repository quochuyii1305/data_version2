#include "mqtt_manager.h"

const char *mqtt_server = "997d108d7c76499ba4d812a8b07fa63c.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char *mqtt_username = "quochuyii1305";
const char *mqtt_password = "Quochuyii1305";

WiFiClientSecure espClient;
PubSubClient client(espClient);

void setup_mqtt()
{
    espClient.setInsecure();
    client.setServer(mqtt_server, mqtt_port);
    // Tăng buffer để đủ chứa mảng 25 data
    client.setBufferSize(640);
}

void mqtt_loop()
{
    if (!client.connected())
    {
        client.connect("ESP32Client_Datn", mqtt_username, mqtt_password);
    }
    else
    {
        client.loop();
    }
}

void mqtt_publish_batch(
    float *ecg_array,
    int size,
    float hr,
    float sdnn,
    float rmssd,
    float ibi)
{
    if (!client.connected()) {
        return;
    }

    char payload[640];
    int offset = snprintf(payload, sizeof(payload), "{\"ecg\":[");

    for (int i = 0; i < size; i++)
    {
        offset += snprintf(
            payload + offset,
            sizeof(payload) - offset,
            "%.4f%s",
            ecg_array[i],
            (i == size - 1) ? "" : ","
        );
    }

    snprintf(
        payload + offset,
        sizeof(payload) - offset,
        "],\"hr\":%.1f,\"sdnn\":%.1f,\"rmssd\":%.1f,\"ibi\":%.1f}",
        hr,
        sdnn,
        rmssd,
        ibi
    );

    client.publish("ecg/data", payload);
}
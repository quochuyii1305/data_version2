# Heart Protect

Heart Protect là hệ thống theo dõi tín hiệu điện tâm đồ (ECG) và biến thiên nhịp tim (HRV), gồm PCB đo ECG tự thiết kế sử dụng ESP32-S3 và AD8232 cùng ứng dụng Flutter. PCB thu nhận, xử lý và gửi dữ liệu qua MQTT/TLS; ứng dụng hiển thị dạng sóng ECG, quản lý hồ sơ bệnh nhân và lưu lịch sử đo trên Firebase.

> Dự án phục vụ mục đích học tập và nghiên cứu. Kết quả hiển thị không thay thế chẩn đoán hoặc thiết bị y tế chuyên dụng.

## Chức năng chính

- Thu nhận ECG bằng PCB tự thiết kế tích hợp ESP32-S3 và AD8232.
- Đăng ký, đăng nhập bằng email/mật khẩu hoặc Google và đặt lại mật khẩu.
- Kết nối MQTT broker qua TLS và theo dõi trạng thái kết nối.
- Nhận, giải mã và hiển thị tín hiệu ECG theo thời gian thực.
- Hiển thị nhịp tim (HR), khoảng IBI và các chỉ số HRV gồm SDNN, RMSSD.
- Tính lại kết quả HRV cuối phiên từ danh sách RR/IBI.
- Quản lý hồ sơ bệnh nhân và đánh giá HRV theo nhóm tuổi, giới tính.
- Lưu metadata bản ghi trong Cloud Firestore.
- Lưu mẫu ECG và danh sách RR dưới dạng JSON trong Firebase Storage.
- Xem lại hoặc xóa lịch sử đo của từng bệnh nhân.

## Luồng dữ liệu

```text
Điện cực ECG
      |
      v
AD8232 trên PCB tự thiết kế
  (thu nhận và xử lý analog)
      |
      v
ESP32-S3
  (ADC 250 Hz, xử lý ECG/HRV)
      |
      | Wi-Fi - JSON qua MQTT/TLS
      v
HiveMQ Cloud (topic: ecg/data)
      |
      v
Flutter app -> Đồ thị ECG + HR/HRV
      |
      +-> Cloud Firestore: người dùng, bệnh nhân, metadata bản ghi
      +-> Firebase Storage: ecg.json, rr.json
```

## Phần cứng

Phần đo ECG không sử dụng một bộ kit hoàn chỉnh có sẵn mà được xây dựng trên PCB thiết kế riêng cho dự án.

| Khối | Vai trò |
| --- | --- |
| Điện cực ECG | Thu tín hiệu điện thế sinh học từ người đo |
| AD8232 | Khối analog front-end dùng để thu nhận, khuếch đại và lọc tín hiệu ECG trước khi đưa vào ADC |
| ESP32-S3 | Lấy mẫu ngõ ra AD8232 bằng ADC, xử lý dữ liệu và truyền qua Wi-Fi/MQTT |
| PCB tự thiết kế | Tích hợp các khối xử lý, analog, nguồn và kết nối của hệ thống |

Firmware phía ESP32-S3 thực hiện các nhiệm vụ chính:

- Lấy mẫu ECG với tần số 250 Hz.
- Gom các mẫu ECG thành từng nhóm để gửi; ứng dụng hiện hỗ trợ payload chứa khoảng 25 mẫu mỗi lần.
- Xác định nhịp tim và khoảng RR/IBI.
- Tính các chỉ số HRV tạm thời như SDNN và RMSSD.
- Đóng gói dữ liệu JSON rồi publish lên topic `ecg/data` qua MQTT/TLS.

Repository hiện chứa source của ứng dụng Flutter. Schematic, PCB layout, BOM, Gerber, pin mapping và firmware ESP32-S3 chưa được lưu trong repository này, vì vậy README chỉ mô tả kiến trúc phần cứng ở mức hệ thống và không giả định sơ đồ chân.

### An toàn thử nghiệm

- PCB là nguyên mẫu nghiên cứu, chưa phải thiết bị y tế được chứng nhận.
- Khi điện cực đang gắn trên người, chỉ sử dụng nguồn và giải pháp cách ly phù hợp cho thiết bị đo tín hiệu sinh học.
- Không kết nối đồng thời người đo với thiết bị USB, debugger hoặc máy đo tham chiếu lưới điện nếu hệ thống chưa có cách ly điện thích hợp.
- Không sử dụng kết quả để tự chẩn đoán hoặc thay thế đánh giá của nhân viên y tế.

Tài liệu linh kiện:

- [AD8232 Datasheet - Analog Devices](https://www.analog.com/media/en/technical-documentation/data-sheets/ad8232.pdf)
- [ESP32-S3 Datasheet - Espressif](https://www.espressif.com/sites/default/files/documentation/esp32-s3_datasheet_en.pdf)
- [ESP32-S3 ADC Continuous Mode - Espressif](https://docs.espressif.com/projects/esp-idf/en/stable/esp32s3/api-reference/peripherals/adc/adc_continuous.html)

## Công nghệ sử dụng

| Thành phần | Công nghệ |
| --- | --- |
| Ứng dụng | Flutter, Dart |
| Xác thực | Firebase Authentication, Google Sign-In |
| Dữ liệu nghiệp vụ | Cloud Firestore |
| Dữ liệu ECG/RR | Firebase Storage |
| Dữ liệu thời gian thực | MQTT qua TLS (`mqtt_client`) |

## Định dạng dữ liệu MQTT

Ứng dụng subscribe topic `ecg/data` với QoS 0. Payload là JSON và có cấu trúc:

```json
{
  "ecg": [0.12, 0.15, 0.18],
  "hr": 72,
  "ibi": 833,
  "sdnn": 42.5,
  "rmssd": 35.1
}
```

Trong đó:

- `ecg`: một giá trị hoặc danh sách mẫu ECG; trường bắt buộc để vẽ tín hiệu.
- `hr`: nhịp tim, đơn vị BPM.
- `ibi`: khoảng thời gian giữa hai nhịp liên tiếp, đơn vị ms. Có thể gửi bằng khóa `rr` để tương thích dữ liệu cũ.
- `sdnn`, `rmssd`: chỉ số HRV tạm thời; có thể bỏ qua nếu thiết bị không tính.

## Yêu cầu

- Flutter SDK tương thích với Dart `^3.11.1`.
- Android Studio hoặc Xcode nếu chạy trên thiết bị di động.
- JDK 17 khi build Android.
- PCB đo ECG tự thiết kế sử dụng ESP32-S3 và AD8232.
- Firmware ESP32-S3 được cấu hình lấy mẫu 250 Hz, kết nối Wi-Fi và publish MQTT.
- Một Firebase project đã bật Authentication, Cloud Firestore và Storage.
- Một MQTT broker và thiết bị publish đúng định dạng dữ liệu phía trên.

## Cài đặt và chạy

### 1. Clone repository

```bash
git clone https://github.com/quochuyii1305/data_version2.git
cd data_version2
```

### 2. Cài dependency

```bash
flutter pub get
```

### 3. Cấu hình Firebase

Repository đã có cấu hình cho Android, iOS, macOS, Windows và Web. Nếu sử dụng Firebase project khác, hãy tạo lại cấu hình bằng FlutterFire CLI:

```bash
flutterfire configure
```

Sau đó:

- Bật phương thức Email/Password trong Firebase Authentication.
- Cấu hình Google Sign-In nếu cần sử dụng đăng nhập Google.
- Tạo Firestore database và Firebase Storage.
- Thiết lập Security Rules phù hợp trước khi triển khai thực tế.

Linux hiện chưa được cấu hình trong `firebase_options.dart`.

### 4. Cấu hình MQTT

Các thông số broker đang nằm trong `MqttConfig` tại `lib/services/mqtt_service.dart`:

```dart
class MqttConfig {
  static const String host = 'YOUR_BROKER_HOST';
  static const String username = 'YOUR_USERNAME';
  static const String password = 'YOUR_PASSWORD';
  static const int port = 8883;
  static const bool useTls = true;
  static const String clientId = 'YOUR_UNIQUE_CLIENT_ID';
  static const String ecgTopic = 'ecg/data';
}
```

Mỗi client kết nối đồng thời nên có `clientId` riêng để tránh broker ngắt kết nối client cũ.

Không commit username, password hoặc token thật vào repository công khai. Với môi trường production, nên chuyển cấu hình nhạy cảm sang biến build/runtime hoặc một cơ chế quản lý secret phù hợp và thay thông tin đăng nhập đã từng bị lộ.

### 5. Chạy ứng dụng

```bash
flutter run
```

Liệt kê thiết bị khả dụng:

```bash
flutter devices
```

Chạy trên thiết bị cụ thể:

```bash
flutter run -d <device-id>
```

## Quy trình đo ECG/HRV

1. Đăng nhập hoặc tạo tài khoản.
2. Cấp nguồn an toàn cho PCB, gắn điện cực và khởi động firmware ESP32-S3.
3. Đảm bảo ESP32-S3 đã kết nối Wi-Fi và publish dữ liệu lên MQTT broker.
4. Kết nối MQTT broker ở tab Trang chủ.
5. Mở tab Đo và bắt đầu nhận tín hiệu ECG.
6. Đo tối thiểu 5 phút và thu được ít nhất 120 khoảng RR/IBI để lưu đánh giá HRV cuối phiên.
7. Chọn bệnh nhân có sẵn hoặc tạo hồ sơ mới.
8. Lưu kết quả và xem lại trong tab Bệnh nhân.

## Cấu trúc dữ liệu Firebase

```text
users/{uid}
└── patients/{patientId}
    └── recordings/{recordingId}
```

Các file mẫu được lưu trên Firebase Storage:

```text
users/{uid}/patients/{patientId}/recordings/{recordingId}/ecg.json
users/{uid}/patients/{patientId}/recordings/{recordingId}/rr.json
```

## Cấu trúc source code

```text
lib/
├── main.dart                 # Khởi tạo Firebase và ứng dụng
├── models/                   # User, patient và ECG recording models
├── screens/                  # Màn hình đăng nhập, đo và quản lý bệnh nhân
├── services/                 # Authentication, MQTT, Firestore và Storage
├── utils/                    # Khoảng tham chiếu và đánh giá HRV
└── widgets/                  # Thành phần giao diện, ECG painter
```

## Kiểm tra chất lượng

```bash
flutter analyze
flutter test
```

Định dạng source code:

```bash
dart format lib test
```

## Lưu ý khi phát triển

- Không coi một MQTT message là một phiên đo hoàn chỉnh; ứng dụng ghép nhiều mẫu vào buffer theo thời gian.
- Kiểm tra đơn vị ECG, HR và RR/IBI giữa firmware với ứng dụng trước khi đánh giá kết quả.
- Không lưu trực tiếp secret trong source code.
- Luôn kiểm tra Firebase Security Rules trước khi đưa ứng dụng lên môi trường thực tế.
- Khi thay đổi schema Firestore hoặc JSON MQTT, cần cập nhật đồng thời model, service và firmware gửi dữ liệu.

import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:datn_20224010/models/ecg_model.dart';

class MqttConfig {
  // địa chỉ broker mqtt cloud
  static const String host =
      '997d108d7c76499ba4d812a8b07fa63c.s1.eu.hivemq.cloud';
  static const String username = 'quochuyii1305';
  static const String password = 'Quochuyii1305';
  static const int port = 8883;
  static const bool useTls = true;
  static const String clientId = 'flutter_ecg_app';
  static const String ecgTopic = 'ecg/data';
}

class MqttService {
  // singleton
  MqttService._();
  static final MqttService instance = MqttService._();

  MqttServerClient? _client;

  //stream ecg
  // tạo 1 trung gian phát dữ liệu giữa mqtt sang UI (nguồn phát dữ liệu)
  final _ctrl = StreamController<EcgModel>.broadcast(); // broadcast stream, cho phép nhiều thằng lắng nghe
  // getter trả ra stream chỉ đọc cho bên ngoài subcribe
  Stream<EcgModel> get ecgStream => _ctrl.stream;

  // kiểm tra trạng thái kết nối hiện tại
  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  // callback để báo cho UI biết trạng thái đã thay đổi
  void Function()? onStateChanged;

  Future<bool> connect() async {
    // tạo client MQTT với host,  clientId, port
    _client = MqttServerClient.withPort(
      MqttConfig.host,
      MqttConfig.clientId,
      MqttConfig.port,
    );

    // cấu hình client
    _client!
      ..logging(on: false)
      ..secure = MqttConfig.useTls
      ..keepAlivePeriod = 30
      ..connectTimeoutPeriod = 8000
      ..autoReconnect = true
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onAutoReconnect = _onAutoReconnect;

    // callback khi reconnect thành công
    _client!.onAutoReconnected = _onAutoReconnected;
    

    // tạo gói tin kết nối MQTT
    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(MqttConfig.clientId)

        // xác thực tài khoản
        .authenticateAs(MqttConfig.username, MqttConfig.password)
        .withWillQos(MqttQos.atMostOnce)
        .startClean();
    try {
      await _client!.connect();
    } catch (e) {
      print('Lỗi kết nố: $e');
      _client!.disconnect();
      return false;
    }
    // nếu chưa kết nối thành công
    if (!isConnected) {
      print('[MQTT] Kết nối thất bại');
      return false;
    }

    // sau khi connect thành công
    _subscribe(); // đăng ký topic
    _listen(); // lắng nghe dữ liệu

    return true;
  }

  // ================= SUBSCRIBE =================
  void _subscribe() {
    // đăng ký topic ecg/data
    _client?.subscribe(MqttConfig.ecgTopic, MqttQos.atMostOnce);
    print('[MQTT] Subscribed: ${MqttConfig.ecgTopic}');
  }

  // ================= LISTEN =================
  void _listen() {
    // mở luồng lắng nghe stream từ broker, khi tin nhắn gửi về MQTT sẽ được chứa trong msgs
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>>msgs) {
      // duyệt qua danh sách tin nhắn
      for (final msg in msgs) {
        // nếu không đúng topic thì bỏ qua
        if (msg.topic != MqttConfig.ecgTopic) continue;

        // ép các gói tin nhận được về kiểu publish message
        final pub = msg.payload as MqttPublishMessage;
        // giải mã dữ liệu nhận được bên trong gói tin từ byte sang string
        final payload = MqttPublishPayload.bytesToStringAsString(
          pub.payload.message, // dữ liệu do esp gửi lên, là mảng byte
        );
        // tạo đối tượng từ dữ liệu nhận được, gán nó vào point
        try {
          // tạo đối tượng ecgmodel từ dữ liệu json
          final point = EcgModel.fromJson(payload);
          
          // nếu stream chưa đóng thì phát dữ liệu cho UI
          if (!_ctrl.isClosed) {
            // them đối tượng vào stream
            _ctrl.add(point);
          }
        } catch (e) {
          print('[MQTT] Parse lỗi: $e');
        }
      }
    });
  }

  // ================= CALLBACK =================
  void _onConnected() {
    print('[MQTT] ✓ Kết nối thành công');
    onStateChanged?.call();
  }

  void _onDisconnected() {
    print('[MQTT] ✗ Mất kết nối');
    
    // báo cho UI biết trạng thái thay đổi
    onStateChanged?.call();
  }

  void _onAutoReconnect() {
    print('[MQTT] Đang reconnect...');
  }

  void _onAutoReconnected() {
    print('[MQTT] Reconnected');
    _subscribe(); // subscribe lại
  }

  // ================= DISCONNECT =================
  void disconnect() {
    _client?.disconnect();
  }

  void dispose() {
    disconnect();
    _ctrl.close();
  }
}

import "dart:async";
import 'package:datn_20224010/models/ecg_model.dart';
import 'package:flutter/material.dart';
import 'package:datn_20224010/services/mqtt_service.dart';
import 'package:datn_20224010/services/patient_service.dart';
import 'package:datn_20224010/widgets/ecg_painter.dart';

class DoTab extends StatefulWidget {
  DoTab({super.key});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _DoTabState();
  }
}

class _DoTabState extends State<DoTab> {
  static const Color _primaryGreen = Color(0xFF1E7D4F);
  static const Color _lightGreen = Color(0xFFE8F5EE);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF8A8A8A);
  static const Color _ecgGreen = Color(0xFF00E676);

  // trạng thái màn hình
  bool _isConnecting = false; // đang kết nối MQTT → hiện loading
  bool _isRecording = false; // đang ghi data → hiện nút Dừng
  bool _hasStopped = false; // đã dừng → hiện phần Lưu
  String _statusMsg = 'Chưa kết nối'; // chữ trạng thái dưới tiêu đề
  static const int _visiblePoints = 200; // số điểm hiển thị trên đồ thị

  // Data ECG
  // _displayBuffer: chỉ giữ 200 điểm gần nhất để vẽ đồ thị
  final List<double> _displayBuffer = [];
  // _sessionData: giữ toàn bộ data từ lúc bắt đầu đến lúc dừng để lưu trên Firestor
  final List<double> _sessionData = [];

  // chỉ số
  int _heartRate = 0;
  int _elapsedSecs = 0; // số giây đã đo

  // Timer & subscription
  StreamSubscription<EcgModel>? _mqttSub; // lắng nghe stream ECG từ MQTT
  Timer? _renderTimer;
  Timer? _durationTimer;

  @override
  void dispose() {
    // hủy hết khi rời màn hình
    _mqttSub?.cancel();
    _renderTimer?.cancel();
    _durationTimer?.cancel();
    MqttService.instance.onStateChanged = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (MqttService.instance.isConnected) {
      _statusMsg = 'Sẵn sàng đo';
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            SizedBox(height: 16),
            _buildEcgChart(),
            SizedBox(height: 16),
            _buildMetrics(),
            SizedBox(height: 24),
            _buildControlButton(),

            // chỉ hiện khi đã dừng đo
            if (_hasStopped) ...[SizedBox(height: 20), _buildSaveSection()],
          ],
        ),
      ),
    );
  }

  // header của màn hình thể hiện tình trạng hiện tại
  Widget _buildHeader() {
    Color statusColor = _textGrey;
    if (_isConnecting) statusColor = Colors.orange;
    if (_isRecording) statusColor = Colors.redAccent;
    if (_hasStopped) statusColor = _primaryGreen;
    return Container(
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _lightGreen,
            ),
            child: Icon(Icons.monitor_heart, color: _primaryGreen, size: 40),
          ),
          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đo ECG',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  _statusMsg,
                  style: TextStyle(fontSize: 13, color: statusColor),
                ),
              ],
            ),
          ),
          if (_isConnecting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  // màn hình hiển thị dữ liệu ECG
  Widget _buildEcgChart() {
    final connected = MqttService.instance.isConnected;
    return Container(
      height: 250,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _ecgGreen, blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // tiêu đề
          Row(
            children: [
              Text(
                'ECG Heart Monitor',
                style: TextStyle(
                  color: Color(0xFF4FC3F7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Spacer(),

              _buildMqttBadge(connected),
            ],
          ),
          SizedBox(height: 8),

          //vùng vẽ đồ thị
          Expanded(
            child: _displayBuffer.length < 2
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sensors, color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          _isConnecting
                              ? 'Đang kết nối broker...'
                              : 'Bấm "Bắt đầu đo" để nhận tín hiệu',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    // widget cắt clip widget con bên trong nó thành hình chữ nhật có góc bo tròn
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: EcgPainter(
                        points: List.from(_displayBuffer),
                        color: _ecgGreen,
                      ),
                      child: SizedBox.expand(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // trạng thái MQTT (MQTT/OFFLINE)
  Widget _buildMqttBadge(bool connected) {
    final c = connected ? _ecgGreen : Colors.redAccent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // dấu trạng thái kết nối
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: c.withOpacity(0.95),
              shape: BoxShape.circle,
            ),
          ),

          SizedBox(width: 4),
          Text(
            connected ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              color: c,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // card hiển thị nhịp tim và bộ đếm thời gian
  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      SizedBox(width: 3),
                      Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    // chỉ hiện số liệu khi đang đo hoặc đã dừng
    final show = _isRecording || _hasStopped;
    return Row(
      children: [
        // card nhịp tim
        Expanded(
          child: _buildMetricCard(
            icon: Icons.favorite,
            iconColor: Colors.redAccent,
            label: 'Nhịp tim',
            value: show && _heartRate > 0 ? '$_heartRate' : '--',
            unit: 'BPM',
          ),
        ),
        SizedBox(width: 12),

        Expanded(
          child: _buildMetricCard(
            icon: Icons.timer_outlined,
            iconColor: _primaryGreen,
            label: 'Thời gian đo',
            value: show ? _timeStr : '--:--',
            unit: '',
          ),
        ),
      ],
    );
  }

  // chuyển số giây thành sạng "mm:ss"
  String get _timeStr {
    final m = _elapsedSecs ~/ 60;
    final s = _elapsedSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // nút điều khiển trung tâm
  Widget _buildActionButton({
    required VoidCallback? onPress,
    required Color color,
    required IconData icon,
    required String label,
    bool loading = false,
  }) {
    return ElevatedButton(
      onPressed: onPress,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color,
        disabledForegroundColor: Colors.white70,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: onPress != null ? 2 : 0, // đổ bóng 2 nếu button được bấm
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            Icon(icon, size: 22),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    // đang kết nối -> hiện loading
    if (_isConnecting) {
      return _buildActionButton(
        onPress: null,
        color: _primaryGreen,
        icon: Icons.hourglass_top,
        label: 'Đang kết nối...',
        loading: true,
      );
    }

    //đang ghi, hiện nút dừng
    if (_isRecording) {
      return _buildActionButton(
        onPress: _stopRecording,
        color: Colors.redAccent,
        icon: Icons.stop_circle_outlined,
        label: 'Dừng đo',
      );
    }

    //đã dừng -> hiện thông báo
    if (_hasStopped) {
      return _buildActionButton(
        onPress: null,
        color: _primaryGreen.withOpacity(0.4),
        icon: Icons.check_circle_outline_outlined,
        label: 'Đã có dữ liệu - lưu bên dưới',
      );
    }

    //mặc định -> hiện nút bắt đầu
    return _buildActionButton(
      onPress: _connectAndStart,
      color: _primaryGreen,
      icon: Icons.play_circle_outline,
      label: 'Bắt đầu đo',
    );
  }

  Future<void> _connectAndStart() async {
    // nếu chưa kết nối -> kết nối mới
    // nếu đã kết nối từ HomeTab -> dùng luôn

    if (!MqttService.instance.isConnected) {
      setState(() {
        _isConnecting = true;
        _statusMsg = 'Đang kết nối HiveMQ Cloud...';
      });

      // callback khi trạng thái MQTT thay đổi -> rebuild UI
      MqttService.instance.onStateChanged = () {
        if (mounted) setState(() {});
      };

      final ok = await MqttService.instance.connect();

      //kết nối thất bại -> dừng lại
      if (!ok || !mounted) {
        setState(() {
          _isConnecting = false;
          _statusMsg = 'Không kết nối được';
        });
        return;
      }
    }

    // đã kết nối -> bắt đầu ghi
    if (!mounted) return;
    setState(() {
      _isConnecting = false;
      _isRecording = true;
      _hasStopped = false;
      _statusMsg = 'Đang ghi...';
      _displayBuffer.clear(); // xóa data cũ
      _sessionData.clear();
      _heartRate = 0;
      _elapsedSecs = 0;
    });

    // lắng nghe stream ECG từ MQTT
    _mqttSub = MqttService.instance.ecgStream.listen((point) {
      _onNewPoint(point);
    });

    // cứ 30s rebuild UI 1 lần

    _renderTimer = Timer.periodic(Duration(microseconds: 30), (_) {
      if (mounted && _isRecording) setState(() {});
    });

    // cứ 1 giây tăng _elapsedSecs lên 1
    _durationTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSecs++;
        });
      }
    });
  }

  // nhận từng điểm data để vẽ đồ thị
  void _onNewPoint(EcgModel point) {
    if (!_isRecording) return;

    // thêm vào displaybuffer để vẽ đồ thị
    _displayBuffer.add(point.ecg);

    // giữ 200 điểm gần nhất, xóa điểm cũ nhất nếu vượt quá
    if (_displayBuffer.length > _visiblePoints) _displayBuffer.removeAt(0);

    //lưu toàn bộ data để lưu firestore sau
    _sessionData.add(point.ecg);

    // cập nhật nhịp tim nếu ESP32 có gửi
    if (point.hr != null) {
      _heartRate = point.hr!;
    }
  }

  void _stopRecording() {
    // hủy hết timer và subscription
    _mqttSub?.cancel();
    _durationTimer?.cancel();
    _renderTimer?.cancel();
    setState(() {
      _isRecording = false;
      _hasStopped = true;
      _statusMsg = 'Đã dừng';
    });
  }

  //Đo lại

  void _reset() {
    _renderTimer?.cancel();
    setState(() {
      _hasStopped = false;
      _displayBuffer.clear();
      _sessionData.clear();
      _heartRate = 0;
      _elapsedSecs = 0;
      _statusMsg = 'Sẵn sàng';
    });
  }

  Widget _buildSaveSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // tiêu đề
          Row(
            children: [
              Icon(Icons.save_alt_outlined, color: _primaryGreen, size: 22),
              SizedBox(width: 8),
              Text(
                'Lưu kết quả đo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // tóm tắt kết quả
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  label: 'Số mẫu',
                  value: '${_sessionData.length}',
                ),
                _buildSummaryItem(label: 'HR', value: '$_heartRate BPM'),
                _buildSummaryItem(label: 'Thời gian', value: _timeStr),
              ],
            ),
          ),

          SizedBox(height: 14),

          // lưu vào bệnh nhân có sẵn
          OutlinedButton.icon(
            onPressed: _showSaveToExistingDialog,
            icon: Icon(Icons.person_2_outlined),
            label: Text('Lưu vào bệnh nhân có sẵn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryGreen,
              side: BorderSide(color: _primaryGreen),
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          SizedBox(height: 10),

          ElevatedButton.icon(
            onPressed: _showSaveToNewPatientDialog,
            icon: Icon(Icons.person_add_outlined),
            label: Text('Tạo bệnh nhân mới vào lưu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          SizedBox(height: 10),
          // đo lại
          TextButton.icon(
            icon: Icon(Icons.refresh, color: _textGrey,),
            onPressed: _reset,
            label: Text('Đo lại', style: TextStyle(color: _textGrey)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _primaryGreen,
          ),
        ),

        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: _textGrey)),
      ],
    );
  }

  //Lưu vào bênh nhân có sẵn
  Future<void> _showSaveToExistingDialog() async {
    //lấy danh sách bệnh nhân từ Firestore
    final patients = await PatientService.instance.fetchPatients();
    if (!mounted) return;

    if (patients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chưa có bệnh nhân. Hãy tạo mới')));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chọn bệnh nhân'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: patients.length,
            itemBuilder: (ctx, i) {
              final p = patients[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _lightGreen,
                  child: Text(
                    p.initial,
                    style: TextStyle(
                      color: _primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(p.hoTen),
                subtitle: p.subtitle.isNotEmpty ? Text(p.subtitle) : null,
                onTap: () {
                  Navigator.pop(context);
                  _saveRecording(patientId: p.id, patientName: p.hoTen);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
        ],
      ),
    );
  }
  // tạo bệnh nhân mới và lưu

  void _showSaveToNewPatientDialog() {
    final hotenCtrl = TextEditingController();
    final ngaySinhCtrl = TextEditingController();
    String? selectedGt;

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          title: Text('Tạo bệnh nhân mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hotenCtrl,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 12),
                TextField(
                  controller: ngaySinhCtrl,
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh (dd/mm/yyyy)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.datetime,
                ),

                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGt,
                  decoration: InputDecoration(
                    labelText: 'Giới tính',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                    DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                  ],
                  onChanged: (v) => setDS(() => selectedGt = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('Hủy'),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  final patient = await PatientService.instance.addPatient(
                    hoTen: hotenCtrl.text,
                    ngaySinh: ngaySinhCtrl.text,
                    gioiTinh: selectedGt,
                    ghiChu: '',
                  );
                  if (!mounted) return;
                  Navigator.pop(dCtx);
                  _saveRecording(
                    patientId: patient.id,
                    patientName: patient.hoTen,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text('Tạo & lưu'),
            ),
          ],
        ),
      ),
    );
  }

  // Lưu recording lên firestore

  Future<void> _saveRecording({
    required String patientId,
    required String patientName,
  }) async {
    try {
      await PatientService.instance.saveRecording(
        patientId: patientId,
        data: _sessionData,
        heartRate: _heartRate,
        duration: _elapsedSecs,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu ${_sessionData.length} mẫu vào: $patientName'),
          backgroundColor: _primaryGreen,
        ),
      );
      _reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

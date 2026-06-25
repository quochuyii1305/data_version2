import 'dart:async';
import 'package:datn_20224010/models/ecg_recording.dart';
import 'package:flutter/material.dart';
import 'package:datn_20224010/services/patient_service.dart';
import 'package:datn_20224010/widgets/ecg_painter.dart';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';

class EcgRecordingScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const EcgRecordingScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  static const Color _primaryGreen = Color(0xFF1E7D4F);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          patientName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<EcgRecording>>(
        // UI nhân 1 stream có danh sách các recording mà watchRecordings đã chuyển từ map sang object gom vào list
        stream: PatientService.instance.watchRecordings(
          patientId,
        ), // gọi hàm watchRecording để lắng nghe collection
        builder: (context, snapshot) {
          // mỗi lần stream có dữ liệu mới, streambuilder sẽ gọi lại builder đưa dữ liệu vào snapshot
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final recordings = snapshot.data ?? [];
          if (recordings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    size: 64,
                    color: _primaryGreen.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có kết quả đo nào',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vào tab Đo để đo ECG và lưu vào bệnh nhân này',
                    style: TextStyle(fontSize: 13, color: _textGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: recordings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _RecordingCard(recording: recordings[i], patientId: patientId),
          );
        },
      ),
    );
  }
}

class _RecordingCard extends StatefulWidget {
  final EcgRecording recording;
  final String patientId;

  const _RecordingCard({required this.recording, required this.patientId});

  @override
  State<_RecordingCard> createState() => _RecordingCardState();
}

class _RecordingCardState extends State<_RecordingCard> {
  static const Color _primaryGreen = Color(0xFF1E7D4F);
  static const Color _lightGreen = Color(0xFFE8F5EE);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF8A8A8A);
  static const Color _ecgGreen = Color(0xFF00E676);
  static const int _visiblePts = 500;

  bool _isPlaying = false;
  List<double> _display = [];
  int _cursor = 0;
  Timer? _timer;

  List<double> _raw = [];
  bool _loadingData = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadEcgData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Hàm xử lý phát hoặc dừng đồ thị
  void _togglePlay() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
      return;
    }

    if (_raw.isEmpty) return;

    // Nếu bắt đầu từ đầu, xóa sạch mảng để vẽ mới
    if (_cursor == 0) _display.clear();

    setState(() => _isPlaying = true);

    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (!mounted) return;

      setState(() {
        // NẠP DỮ LIỆU CỐ ĐỊNH
        for (int i = 0; i < 5; i++) {
          if (_cursor < _raw.length) {
            double newVal = _raw[_cursor++];

            // CƠ CHẾ FIFO: Nếu mảng đã đầy, xóa phần tử đầu, thêm phần tử cuối
            if (_display.length >= _visiblePts) {
              _display.removeAt(0);
            }
            _display.add(newVal);
          }
        }
      });

      if (_cursor >= _raw.length) {
        _timer?.cancel();
        setState(() => _isPlaying = false);
      }
    });
  }

  // Tua đến vị trí bất kỳ dựa trên tỷ lệ slider
  void _seekTo(double ratio) {
    _timer?.cancel();
    final newCursor = (ratio * _raw.length).toInt().clamp(0, _raw.length);

    // Trích xuất tối đa 200 điểm trước vị trí tua để làm mượt đồ thị tĩnh
    final start = (newCursor - _visiblePts).clamp(0, _raw.length);
    setState(() {
      _cursor = newCursor;
      _display = _raw.sublist(start, newCursor);
      _isPlaying = false;
    });
  }

  // Đưa đồ thị và thời gian quay về mốc ban đầu
  void _reset() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _cursor = 0;
      final end = _raw.length.clamp(0, _visiblePts);
      _display = _raw.sublist(0, end);
    });
  }

  double get _progress => _raw.isEmpty ? 0.0 : _cursor / _raw.length;

  // Đổi số lượng mẫu dữ liệu ra định dạng phút:giây
  String _formatTime(int sampleIndex) {
    const double msPerSample = 4.0;
    final ms = (sampleIndex * msPerSample).toInt();
    final sec = (ms ~/ 1000) % 60;
    final min = ms ~/ 60000;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.recording;
    final totalStr = _formatTime(_raw.length);
    final curStr = _formatTime(_cursor);


    if (_loadingData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Không tải được dữ liệu ECG: $_loadError',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phần hiển thị thông tin tiêu đề thẻ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: _lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    color: _primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.dateStr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${rec.heartRate} BPM',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textGrey,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.timer_outlined,
                                color: _primaryGreen,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rec.durationStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textGrey,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.data_usage,
                                color: _primaryGreen,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${rec.samples} mẫu',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),

          // Khu vực vẽ đồ thị sóng ECG
          Container(
            height: 160,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _display.length < 2
                ? const Center(
                    child: Text(
                      'Không có dữ liệu',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: EcgPainter(
                        points: List.from(_display),
                        color: _ecgGreen,
                        sampleRateHz: 250,
                        visibleSampleCount: _visiblePts,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
          ),

          // Thanh trượt điều chỉnh tua thời gian
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: _primaryGreen,
                    inactiveTrackColor: _lightGreen,
                    thumbColor: _primaryGreen,
                    overlayColor: _primaryGreen.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _progress.clamp(0.0, 1.0),
                    onChanged: _raw.isEmpty ? null : _seekTo,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        curStr,
                        style: const TextStyle(fontSize: 11, color: _textGrey),
                      ),
                      Text(
                        totalStr,
                        style: const TextStyle(fontSize: 11, color: _textGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Các nút bấm điều khiển chức năng
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _reset,
                  icon: const Icon(
                    Icons.skip_previous_rounded,
                    color: _primaryGreen,
                    size: 28,
                  ),
                  tooltip: 'Về đầu',
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _raw.isEmpty ? null : _togglePlay,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(_isPlaying ? 'Dừng' : 'Phát lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _raw.isEmpty
                      ? null
                      : () {
                          const int step = 1250;
                          _seekTo(
                            ((_cursor + step) / _raw.length).clamp(0.0, 1.0),
                          );
                        },
                  icon: const Icon(
                    Icons.forward_5_rounded,
                    color: _primaryGreen,
                    size: 28,
                  ),
                  tooltip: '+5 giây',
                ),
              ],
            ),
          ),

          if (rec.sdnn != null) ...[
            const Divider(height: 1, color: _lightGreen),
            _buildHrvSection(rec),
          ],
        ],
      ),
    );
  }

  // hàm tải file
  Future<void> _loadEcgData() async {
    try {
      final path = widget.recording.ecgPath;
      // vào firebase storage với file nằm tại path
      final bytes = await FirebaseStorage.instance
          .ref(path)
          .getData(20 * 1024 * 1024);

      if (bytes == null) {
        throw Exception('Không tải được file ECG');
      }
      // decode byte ra string json
      final jsonMap = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      final values = (jsonMap['data'] as List? ?? [])
          .map((e) => (e as num).toDouble()) // duyệt từng phần tử e, ép e thành num
          .toList(); // gom lại thành list double

      final end = values.length.clamp(0, _visiblePts);

      setState(() {
        _raw = values;
        _display = values.sublist(0, end);
        _loadingData = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _loadingData = false;
      });
    }
  }

  // Hộp thoại xác nhận trước khi xóa dữ liệu đo
  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa kết quả đo?'),
        content: Text('Xóa bản ghi lúc ${widget.recording.dateStr}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await PatientService.instance.deleteRecording(
        patientId: widget.patientId,
        recordingId: widget.recording.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========================================================
  // KHỐI GIAO DIỆN HRV
  // ========================================================
  Widget _buildHrvSection(EcgRecording rec) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: _primaryGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Chỉ số HRV',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildHrvCard(
                  label: 'SDNN',
                  value: rec.sdnn != null ? rec.sdnn!.toStringAsFixed(1) : '--',
                  unit: 'ms',
                  desc: 'Tổng thể',
                  status: _levelColor(rec.sdnnLevel),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildHrvCard(
                  label: 'RMSSD',
                  value: rec.rmssd != null
                      ? rec.rmssd!.toStringAsFixed(1)
                      : '--',
                  unit: 'ms',
                  desc: 'Phục hồi',
                  status: _levelColor(rec.rmssdLevel),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildHrvCard(
                  label: 'IBI',
                  value: rec.ibi != null ? rec.ibi!.toStringAsFixed(1) : '--',
                  unit: 'ms',
                  desc: 'Khoảng nhịp',
                  status: _primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildHrvAssessmentBox(rec),
        ],
      ),
    );
  }

  Widget _buildHrvCard({
    required String label,
    required String value,
    required String unit,
    required String desc,
    required Color status,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: status.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: status.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: status,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(fontSize: 11, color: _textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 10, color: _textGrey)),
        ],
      ),
    );
  }

  Widget _buildHrvAssessmentBox(EcgRecording rec) {
    final hasAssessment =
        rec.hrvOverallAssessment != null ||
        rec.sdnnAssessment != null ||
        rec.rmssdAssessment != null;

    if (!hasAssessment) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withOpacity(0.35)),
        ),
        child: const Text(
          'Bản ghi này chưa có đánh giá HRV theo tuổi/giới. Hãy đo và lưu lại sau khi cập nhật chức năng đánh giá.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final overallColor = _overallColor(rec);

    final patientInfo = [
      if (rec.patientGender != null) rec.patientGender!,
      if (rec.patientAge != null) '${rec.patientAge} tuổi',
      if (rec.patientAgeGroup != null) 'nhóm ${rec.patientAgeGroup}',
    ].join(' - ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: overallColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: overallColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 18, color: overallColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rec.hrvOverallAssessment ??
                      'Đánh giá HRV theo nhóm tuổi/giới',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: overallColor,
                  ),
                ),
              ),
            ],
          ),

          if (patientInfo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Nhóm tham chiếu: $patientInfo',
              style: const TextStyle(
                fontSize: 12,
                color: _textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 10),

          _buildAssessmentRow(
            label: 'SDNN',
            value: rec.sdnn,
            assessment: rec.sdnnAssessment,
            low: rec.sdnnRefLow,
            high: rec.sdnnRefHigh,
            level: rec.sdnnLevel,
          ),

          const SizedBox(height: 6),

          _buildAssessmentRow(
            label: 'RMSSD',
            value: rec.rmssd,
            assessment: rec.rmssdAssessment,
            low: rec.rmssdRefLow,
            high: rec.rmssdRefHigh,
            level: rec.rmssdLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentRow({
    required String label,
    required double? value,
    required String? assessment,
    required double? low,
    required double? high,
    required String? level,
  }) {
    final color = _levelColor(level);

    String rangeText = '';
    if (low != null && high != null) {
      rangeText =
          'Ngưỡng: ${low.toStringAsFixed(1)} - ${high.toStringAsFixed(1)} ms';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: ${value != null ? value.toStringAsFixed(1) : '--'} ms',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  assessment ?? 'Chưa có đánh giá',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (rangeText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    rangeText,
                    style: const TextStyle(fontSize: 11, color: _textGrey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(String? level) {
    switch (level) {
      case 'low':
        return Colors.redAccent;
      case 'normal':
        return _primaryGreen;
      case 'high':
        return Colors.orange;
      default:
        return _textGrey;
    }
  }

  Color _overallColor(EcgRecording rec) {
    if (rec.sdnnLevel == 'low' || rec.rmssdLevel == 'low') {
      return Colors.redAccent;
    }

    if (rec.sdnnLevel == 'high' || rec.rmssdLevel == 'high') {
      return Colors.orange;
    }

    if (rec.sdnnLevel == 'normal' && rec.rmssdLevel == 'normal') {
      return _primaryGreen;
    }

    return _textGrey;
  }
}

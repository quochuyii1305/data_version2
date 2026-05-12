import 'dart:async';
import 'package:datn_20224010/models/ecg_recording.dart';
import 'package:flutter/material.dart';
import 'package:datn_20224010/services/patient_service.dart';
import 'package:datn_20224010/widgets/ecg_painter.dart';

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
        stream: PatientService.instance.watchRecordings(patientId),
        builder: (context, snapshot) {
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

// CARD RECORDING
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

  bool _isPlaying = false;
  List<double> _display = [];
  int _cursor = 0;
  Timer? _timer;
  List<double> get _raw => widget.recording.data;

  @override
  void initState() {
    super.initState();
    _display = List.from(_raw);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      // đang phát → dừng
      _timer?.cancel();
      setState(() => _isPlaying = false);
      return;
    }

    if (_raw.isEmpty) return;

    // reset về đầu
    _cursor = 0;
    _display = [];

    setState(() => _isPlaying = true);

    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (!mounted) return;

      // hết data → dừng
      if (_cursor >= _raw.length) {
        _timer?.cancel();
        setState(() => _isPlaying = false);
        return;
      }

      setState(() {
        _display.add(_raw[_cursor++]);
        // chỉ giữ 200 điểm gần nhất
        if (_display.length > 200) _display.removeAt(0);
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _cursor = 0;
      _display = List.from(_raw); // hiện lại toàn bộ
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final rec = widget.recording;
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
          // HEADER
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
                      Row(
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

          //  ĐỒ THỊ ECG
          Container(
            height: 160,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                    // bo tròn khung chứa đồ thị
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: EcgPainter(points: _display, color: _ecgGreen),
                      child: const SizedBox.expand(),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _raw.isEmpty ? null : _togglePlay,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                    label: Text(_isPlaying ? 'Dừng' : 'Phát lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryGreen,
                    side: const BorderSide(color: _primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.replay, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

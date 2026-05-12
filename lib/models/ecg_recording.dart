class EcgRecording {
  final String id;
  final List<double> data;
  final int heartRate;
  final int duration;
  final int samples;
  final DateTime? createdAt;

  const EcgRecording({
    required this.id,
    required this.data,
    required this.heartRate,
    required this.duration,
    required this.samples,
    this.createdAt,
  });

  factory EcgRecording.fromMap(Map<String, dynamic> map) {
    return EcgRecording(
      id: map['id'] ?? '',
      data: (map['data'] as List? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      heartRate: (map['heartRate'] as num?)?.toInt() ?? 0,
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      samples: (map['samples'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
  String get durationStr {
    final m = duration ~/ 60; // chia lấy phần nguyên
    final s = duration % 60; // chia lấy dư
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// "27/03/2026  14:35"
  String get dateStr {
    if (createdAt == null) return 'N/A';
    final d = createdAt!;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

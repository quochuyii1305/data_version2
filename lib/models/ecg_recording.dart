class EcgRecording {
  final String id;
  final List<double> data;
  final int heartRate;
  final int duration;
  final int samples;
  final DateTime createdAt;
  final String? ecgPath;
  final String? rrPath;

  final double? sdnn;
  final double? rmssd;
  final double? ibi;

  // Thông tin nhóm tham chiếu
  final int? patientAge;
  final String? patientGender;
  final String? patientAgeGroup;

  // Đánh giá SDNN theo nhóm tuổi/giới
  final String? sdnnLevel; // low / normal / high
  final String? sdnnAssessment;
  final double? sdnnRefLow;
  final double? sdnnRefHigh;

  // Đánh giá RMSSD theo nhóm tuổi/giới
  final String? rmssdLevel; // low / normal / high
  final String? rmssdAssessment;
  final double? rmssdRefLow;
  final double? rmssdRefHigh;

  // Tổng kết chung
  final String? hrvOverallAssessment;

  const EcgRecording({
    required this.id,
    required this.data,
    required this.heartRate,
    required this.duration,
    required this.samples,
    required this.createdAt,

    this.ecgPath,
    this.rrPath,

    this.sdnn,
    this.rmssd,
    this.ibi,
    this.patientAge,
    this.patientGender,
    this.patientAgeGroup,
    this.sdnnLevel,
    this.sdnnAssessment,
    this.sdnnRefLow,
    this.sdnnRefHigh,
    this.rmssdLevel,
    this.rmssdAssessment,
    this.rmssdRefLow,
    this.rmssdRefHigh,
    this.hrvOverallAssessment,
  });

  String get durationStr {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get dateStr {
    final d = createdAt;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'data': data,
        'heartRate': heartRate,
        'duration': duration,
        'samples': samples,
        'createdAt': createdAt.toIso8601String(),

        'ecgPath': ecgPath,
        'rrPath': rrPath,

        'sdnn': sdnn,
        'rmssd': rmssd,
        'ibi': ibi,
        

        'patientAge': patientAge,
        'patientGender': patientGender,
        'patientAgeGroup': patientAgeGroup,

        'sdnnLevel': sdnnLevel,
        'sdnnAssessment': sdnnAssessment,
        'sdnnRefLow': sdnnRefLow,
        'sdnnRefHigh': sdnnRefHigh,

        'rmssdLevel': rmssdLevel,
        'rmssdAssessment': rmssdAssessment,
        'rmssdRefLow': rmssdRefLow,
        'rmssdRefHigh': rmssdRefHigh,

        'hrvOverallAssessment': hrvOverallAssessment,
      };

  factory EcgRecording.fromMap(Map<String, dynamic> map) {
    return EcgRecording(
      id: map['id'] ?? '',
      data: (map['data'] as List? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      heartRate: (map['heartRate'] as num?)?.toInt() ?? 0,
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      samples: (map['samples'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
      ecgPath: map['ecgPath'] as String?,
      rrPath: map['rrPath'] as String?,
      sdnn: (map['sdnn'] as num?)?.toDouble(),
      rmssd: (map['rmssd'] as num?)?.toDouble(),

      // đọc ibi mới, fallback rr nếu dữ liệu cũ từng lưu rr
      ibi: map['ibi'] != null
          ? (map['ibi'] as num).toDouble()
          : (map['rr'] as num?)?.toDouble(),

      patientAge: (map['patientAge'] as num?)?.toInt(),
      patientGender: map['patientGender'] as String?,
      patientAgeGroup: map['patientAgeGroup'] as String?,

      sdnnLevel: map['sdnnLevel'] as String?,
      sdnnAssessment: map['sdnnAssessment'] as String?,
      sdnnRefLow: (map['sdnnRefLow'] as num?)?.toDouble(),
      sdnnRefHigh: (map['sdnnRefHigh'] as num?)?.toDouble(),

      rmssdLevel: map['rmssdLevel'] as String?,
      rmssdAssessment: map['rmssdAssessment'] as String?,
      rmssdRefLow: (map['rmssdRefLow'] as num?)?.toDouble(),
      rmssdRefHigh: (map['rmssdRefHigh'] as num?)?.toDouble(),

      hrvOverallAssessment: map['hrvOverallAssessment'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    // phòng trường hợp Firestore Timestamp có method toDate()
    try {
      final dt = value.toDate();
      if (dt is DateTime) return dt;
    } catch (_) {}

    return DateTime.now();
  }
}
import 'dart:convert';

class EcgModel {
  final List<double> ecg;
  final double? hr;
  final double? sdnn;
  final double? rmssd;
  final double? ibi;

  EcgModel({required this.ecg, this.hr, this.sdnn, this.rmssd, this.ibi});

  factory EcgModel.fromJson(String payload) {
    try {
      final map = jsonDecode(payload.trim()) as Map<String, dynamic>;

      List<double> ecgList = [];

      if (map['ecg'] != null) {
        if (map['ecg'] is List) {
          ecgList = (map['ecg'] as List)
              .map((e) => (e as num).toDouble())
              .toList();
        } else if (map['ecg'] is num) {
          ecgList = [(map['ecg'] as num).toDouble()];
        }
      }

      return EcgModel(
        ecg: ecgList,
        hr: map['hr'] != null ? (map['hr'] as num).toDouble() : null,
        sdnn: map['sdnn'] != null ? (map['sdnn'] as num).toDouble() : null,
        rmssd: map['rmssd'] != null ? (map['rmssd'] as num).toDouble() : null,
        ibi: map['ibi'] != null
            ? (map['ibi'] as num).toDouble()
            : map['rr'] != null
            ? (map['rr'] as num).toDouble()
            : null,
      );
    } catch (e) {
      print('[EcgModel] Parse lỗi: $e');
      return EcgModel(ecg: []);
    }
  }
}

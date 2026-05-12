import 'dart:convert';


class EcgModel {
  late final double ecg;
  late final int? hr;
   EcgModel({
    required this.ecg,
    this.hr,
   });
    // tạo đối tượng từ dữ liệu dạng json
   factory EcgModel.fromJson(String payload){
    try{
      // ép kiểu dữ liệu nhận được dạng json thành map<key,value>
      final map = jsonDecode(payload.trim()) as Map<String,dynamic>;
      return EcgModel(
        ecg: (map['ecg'] as num).toDouble(), 
      hr: map.containsKey('hr') ? (map['hr'] as num).toInt() : null,
      );
    } catch(e){
      _log('[EcgPoint] Parse lỗi: $e | payload: "$payload"');
      return EcgModel(ecg: 0);
    }
   }
}
void _log(String msg) {
  // ignore: avoid_print
  print(msg);
}
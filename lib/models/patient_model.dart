

class PatientModel {
  final String id;
  final String hoTen;
  final String ngaySinh;
  final String? gioiTinh;
  final String? ghiChu;
  final DateTime createdAt;

  PatientModel({
    required this.id,
    required this.hoTen,
    required this.ngaySinh,
    this.gioiTinh,
    this.ghiChu,
    required this.createdAt,
  });
  // chuyển object thành map để lưu trên json
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hoTen': hoTen,
      'ngaySinh': ngaySinh,
      'gioiTinh': gioiTinh,
      'ghiChu': ghiChu,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // tạo đối tượng từ dữ liệu json
  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      id: map['id'] ?? '',
      hoTen: map['hoTen'] ?? '',
      ngaySinh: map['ngaySinh'] ?? '',
      gioiTinh: map['gioiTinh'] ?? 'Khác',
      ghiChu: map['ghiChu'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  //chữ cái đầu tiên để hiện avatar
  String get initial => hoTen.isNotEmpty ? hoTen[0].toUpperCase() : '?';

  // dòng phụ: "01/01/1990 Nam "
  String get subtitle => [
    if (ngaySinh.isNotEmpty) ngaySinh,
    if (gioiTinh != null && gioiTinh!.isNotEmpty) gioiTinh!,
  ].join(' · ');
}

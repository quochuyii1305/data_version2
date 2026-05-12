class UserModel {
  final String uid;
  final String hoTen;
  final String ngaySinh;
  final String email;
  final String soDienThoai;
  final String gioiTinh;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.hoTen,
    required this.ngaySinh,
    required this.email,
    required this.soDienThoai,
    required this.gioiTinh,
    required this.createdAt,
  });

  // chuyen object thành map để lưu trên firebase
  Map<String,dynamic> toMap(){
    return {
      'uid': uid,
      'hoTen': hoTen,
      'ngaySinh': ngaySinh,
      'email': email,
      'soDienThoai': soDienThoai,
      'gioiTinh': gioiTinh,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // tao doi tuong user model tu dữ liệu json
  factory UserModel.fromMap(Map<String,dynamic>map){
    return UserModel(
      uid: map['uid'] ?? '', // lấy dữ liệu từ json
      hoTen: map['hoTen'] ?? '',
      ngaySinh: map['ngaySinh'] ?? '',
      email: map['email'] ?? '',
      soDienThoai: map['soDienThoai'] ?? '',
      gioiTinh: map['gioiTinh'] ?? 'Khác',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Tạo bản sao UserModel với một số trường được thay đổi
// Dùng khi cập nhật thông tin user (ví dụ: đổi tên, đổi ngày sinh)
  UserModel copyWith({
    String? hoTen_,
    String? email_,
    String? soDienThoai_,
    String? ngaySinh_,
    String? gioiTinh_,
    DateTime? createdAt_,
  }) {
    return UserModel(
      uid: uid,
      hoTen: hoTen_ ?? hoTen,
      ngaySinh: ngaySinh_ ?? ngaySinh,
      email: email_ ?? email,
      soDienThoai: soDienThoai_ ?? soDienThoai,
      gioiTinh: gioiTinh_ ?? gioiTinh,
      createdAt: createdAt_ ?? createdAt,
    );
  }
}
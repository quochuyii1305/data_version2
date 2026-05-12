import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';


class UserService {

  // tao 1 bien de tro toi collection user, tu do co the lay thuoc tinh user
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');


  // tao user
  Future<void> createUser(UserModel user) async{
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  // lay thong tin user theo uid
  Future<UserModel?> getUser(String uid) async{
    final doc = await _usersCollection.doc(uid).get();

    if(doc.exists){
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // cap nhat user
  Future<void> updateUser({
    required String uid,
    String? hoTen,
    String? soDienThoai,
    String? ngaySinh,
    String? gioiTinh,
  }) async{
    try{
      // tao map chua cac truong khong null
      final Map<String,dynamic> updates = {};
      if(hoTen != null) updates ['hoTen'] = hoTen;
      if(soDienThoai != null) updates['soDienThoai'] = soDienThoai;
      if(ngaySinh != null) updates ['ngaySinh'] = ngaySinh;
      if(gioiTinh != null) updates ['gioiTinh'] = gioiTinh;

      // update() chi update cac truog chi dinh
      await _usersCollection.doc(uid).update(updates);

    } catch(e) {
      throw Exception('Không thể cập nhật thông tin: $e');
    }
  }


  // xoa user
  Future<void> deleteUser(String uid) async{
    await _usersCollection.doc(uid).delete();
  }
}
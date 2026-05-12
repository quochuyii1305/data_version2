import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '717675957615-97sbqr4httfn5fsqnpgam1dlmdr68nuf.apps.googleusercontent.com',
  );
  User? get currentUser => _auth.currentUser;

  String _parseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu, cần ít nhất 6 ký tự';
      case 'too-many-requests':
        return 'Quá nhiều lần thử, vui lòng thử lại sau';
      default:
        return e.message ?? 'Lỗi xác thực: ${e.code}';
    }
  }

  // đăng nhập bằng email
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _parseAuthError(e);
    }
  }

  // đang ký bằng email
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String hoTen,
    required String ngaySinh,
    required String gioiTinh,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      // luu thong tin nguoi dung vao firebase
      await _db.collection('users').doc(uid).set({
        'hoTen': hoTen,
        'email': email.trim(),
        'ngaySinh': ngaySinh,
        'gioiTinh': gioiTinh,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _parseAuthError(e);
    }
  }

  //đăng nhập bằng google
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Đăng nhập Google bị hủy';

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCred.user;

      if (user != null) {
        // kiem tra xem da co user tren firebase hay chua
        // Lấy dữ liệu của 1 user từ Firestore theo uid
        final doc = await _db.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'hoTen': user.displayName ?? '',
            'ngaySinh': '',
            'gioiTinh': 'Khác',
            'soDienThoai': user.phoneNumber,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _parseAuthError(e);
    } catch (e) {
      // ← thêm cái này
      print("Google Sign-In error: $e");
      return 'Lỗi đăng nhập Google: ${e.toString()}';
    }
  }

  // đặt lại mật khẩu
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _parseAuthError(e);
    } catch (e) {
      return 'Lỗi';
    }
  }

  // đăng xuất
  Future<String?> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    return null;
  }
}

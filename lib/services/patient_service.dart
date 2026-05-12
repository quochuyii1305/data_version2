import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn_20224010/models/ecg_recording.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datn_20224010/models/patient_model.dart';

class PatientService {
  // singleton
  PatientService._();
  static final PatientService instance = PatientService._();

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  // tao 1 bien de tro toi collection user, sau đó trỏ tới collection patients
  // vì mỗi user gồm nhiều patient
  CollectionReference get _patientsCol =>
      _db.collection('users').doc(_uid).collection('patients');
  /*Tủ lớn (Firestore)
└── Ngăn "users"                    ← collection
    └── Hồ sơ của "abc123"          ← document (mỗi user 1 hồ sơ)
        └── Ngăn nhỏ "patients"     ← sub-collection (hộp bên trong hồ sơ)
            ├── Hồ sơ bệnh nhân 1
            ├── Hồ sơ bệnh nhân 2
            └── Hồ sơ bệnh nhân 3 */

  //tạo 1 con trỏ tới collection recordings của 1 bệnh nhân

  CollectionReference _recordingsCol(String patientId) =>
      _patientsCol.doc(patientId).collection('recordings');

  // bệnh nhân

  //stream realtime danh sách bệnh nhân
  Stream<List<PatientModel>> watchPatients() {
    if (_uid == null) return const Stream.empty();
    return _patientsCol
        .orderBy('hoTen') // sắp xếp theo 'họ tên'
        // lắng nghe dữ liệu liên tục, snapshots trả về Stream<QuerySnapshot>,
        // mỗi lần có 1 dữ liệu thay đổi -> có 1 snap
        .snapshots()
        // duyệt qua từng phần tử trong danh sách snap
        .map(
          // duyệt qua từng document trong Firestore
          (snap) => snap.docs
              .map(
                (doc) =>
                    // chuyển doc sang object
                    PatientModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(), // chuyển thành List<PatientModel>
        );
  }

  // Lấy danh sách bệnh nhân từ firestore 1 lần - dùng trong dialog chọn bệnh nhân
  Future<List<PatientModel>> fetchPatients() async {
    if (_uid == null) return [];
    final snap = await _patientsCol.orderBy('hoTen').get();
    return snap.docs
        .map((doc) => PatientModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // thêm bệnh nhân mới, trả về PatientModel vừa tạo
  Future<PatientModel> addPatient({
    required String hoTen,
    required String ngaySinh,
    String? gioiTinh,
    String? ghiChu,
  }) async {
    if (_uid == null) throw Exception('Chưa đăng nhập');
    if (hoTen.trim().isEmpty) throw Exception('Họ tên không được để trống');
    final ref = _patientsCol.doc(); // tự sinh id
    final now = DateTime.now();
    final patient = PatientModel(
      id: ref.id,
      hoTen: hoTen.trim(),
      ngaySinh: ngaySinh.trim(),
      createdAt: now,
      ghiChu: ghiChu?.trim(),
      gioiTinh: gioiTinh,
    );
    // lưu dữ liệu patient lên firestor vào document mà ref đang trỏ tới
    await ref.set(patient.toMap());
    return patient;
  }

  // cập nhật thông tin bệnh nhân
  Future<void> updatePatient({
    required String patientId,
    String? hoTen,
    String? ngaySinh,
    String? gioiTinh,
    String? ghiChu,
  }) async {
    if (_uid == null) throw Exception('Chưa đăng nhập');

    final Map<String, dynamic> updates = {};
    if (hoTen != null) updates['hoTen'] = hoTen.trim();
    if (ngaySinh != null) updates['ngaySinh'] = ngaySinh.trim();
    if (gioiTinh != null) updates['gioiTinh'] = gioiTinh;
    if (ghiChu != null) updates['ghiChu'] = ghiChu.trim();
    await _patientsCol.doc(patientId).update(updates);
  }

  // xóa bệnh nhân và toàn bộ recording
  Future<void> deletePatient(String patientId) async {
    if (_uid == null) throw Exception('Chưa đăng nhập');

    // lấy toàn bộ recordings của bệnh nhân đó về
    final recSnap = await _recordingsCol(patientId).get();
    // duyệt qua từng recording xóa từng cái một
    for (final doc in recSnap.docs) {
      await doc.reference.delete();
    }
    // xóa bệnh nhân
    await _patientsCol.doc(patientId).delete();
  }

  // RECORDING
  //Stream realtime danh sách recording
  Stream<List<EcgRecording>> watchRecordings(String patientId) {
    if (_uid == null) return const Stream.empty();
    return _recordingsCol(
          patientId,
        ) // trỏ đến collection recordings của bênh nhân
        .orderBy(
          'createdAt',
          descending: true,
        ) // sắp xếp theo thời gian tạo, mới nhất lên trên
        .snapshots() // lắng nghe realtime, mỗi khi dữ liệu thay đổi sẽ phát ra 1 snapshot mới
        .map(
          (snap) => snap
              .docs // [doc1, doc2]
              .map(
                (doc) => // duyệt từng document
                    // chuyển từ map sang object
                    EcgRecording.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // lưu bản ghi ecg mới
  Future<void> saveRecording({
    required String patientId,
    required List<double> data,
    required int heartRate,
    required int duration,
  }) async {
    if (_uid == null) throw Exception('Chưa đăng nhập');
    if (data.isEmpty) throw Exception('Không có dữ liệu ECG để lưu');
    final ref = _recordingsCol(patientId).doc();
    await ref.set({
      'id': ref.id,
      'data': data,
      'heartRate': heartRate,
      'duration': duration,
      'samples': data.length,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // xóa một bản ghi ECG
  Future<void> deleteRecording({
    required String patientId,
    required String recordingId,
  }) async {
    if (_uid == null) throw Exception('Chưa đăng nhập');
    await _recordingsCol(patientId).doc(recordingId).delete();
  }
}

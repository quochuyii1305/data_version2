import 'package:datn_20224010/models/patient_model.dart';
import 'package:datn_20224010/services/patient_service.dart';
import 'package:flutter/material.dart';
import 'package:datn_20224010/screens/ecg_recording_screen.dart';

class BenhNhanTab extends StatefulWidget {
  const BenhNhanTab({super.key});

  @override
  State<BenhNhanTab> createState() => _BenhNhanTabState();
}

class _BenhNhanTabState extends State<BenhNhanTab> {
  static const Color _primaryGreen = Color(0xFF1E7D4F);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPatientDialog(context),
        backgroundColor: _primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildPatientList(),
    );
  }

  // danh sách bệnh nhân
  Widget _buildPatientList() {
    return StreamBuilder<List<PatientModel>>(
      stream: PatientService.instance.watchPatients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final patients = snapshot.data ?? [];
        if (patients.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_outlined, size: 64, color: _primaryGreen),
                SizedBox(height: 16),
                Text(
                  'Chưa có bệnh nhân nào',

                  style: TextStyle(
                    fontSize: 16,
                    color: _textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bấm + để thêm',
                  style: TextStyle(fontSize: 16, color: _textGrey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: patients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _PatientCard(patient: patients[i]),
        );
      },
    );
  }

  void _showAddPatientDialog(BuildContext context) {
    final hoTenCtrl = TextEditingController();
    final ngaySinhCtrl = TextEditingController();
    final ghiChuCtrl = TextEditingController();
    String? selectedGT;

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          title: const Text('Thêm bệnh nhân'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hoTenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ngaySinhCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ngày sinh (dd/mm/yyyy)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedGT,
                  decoration: const InputDecoration(
                    labelText: 'Giới tính',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                    DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                    DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                  ],
                  onChanged: (v) => setDS(() => selectedGT = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ghiChuCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => _submitAddPatient(
                dCtx,
                hoTenCtrl,
                ngaySinhCtrl,
                ghiChuCtrl,
                selectedGT,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAddPatient(
    BuildContext context,
    TextEditingController hoTenCtrl,
    TextEditingController ngaySinhCtrl,
    TextEditingController ghiChuCtrl,
    String? gioiTinh,
  ) async {
    try {
      await PatientService.instance.addPatient(
        hoTen: hoTenCtrl.text,
        ngaySinh: ngaySinhCtrl.text,
        gioiTinh: gioiTinh,
        ghiChu: ghiChuCtrl.text,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ── CARD BỆNH NHÂN ────────────────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final PatientModel patient;

  const _PatientCard({required this.patient});

  static const Color _primaryGreen = Color(0xFF1E7D4F);
  static const Color _lightGreen = Color(0xFFE8F5EE);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EcgRecordingScreen(
            patientId: patient.id,
            patientName: patient.hoTen,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // avatar chữ cái đầu
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _lightGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  patient.initial,
                  style: const TextStyle(
                    color: _primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // tên + thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.hoTen,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  if (patient.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      patient.subtitle,
                      style: const TextStyle(fontSize: 13, color: _textGrey),
                    ),
                  ],
                ],
              ),
            ),

            // nút xóa
            const Icon(Icons.chevron_right, color: _textGrey, size: 22),
            IconButton(
              onPressed: () => _confirmDelete(context),
              icon: Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Xóa bệnh nhân',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    // hỏi xác nhận
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xóa bệnh nhân?'),
        content: Text('Xóa "${patient.hoTen}" sẽ xóa luôn tất cả kết quả đo '),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    // người dùng bấm hủy
    if (confirm != true) return;

    // tiến hành xóa
    try {
      await PatientService.instance.deletePatient(patient.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/*1. Mở màn hình lần đầu:
BenhNhanTab được tạo
        ↓
build() chạy → vẽ Scaffold + FAB + _buildPatientList()
        ↓
StreamBuilder bắt đầu lắng nghe watchPatients()
        ↓
ConnectionState.waiting → hiện CircularProgressIndicator
        ↓
Firestore trả data về
        ↓
patients = [] → hiện "Chưa có bệnh nhân"
hoặc
patients = [p1, p2, p3] → ListView tạo 3 _PatientCard

2. Bấm nút + thêm bệnh nhân:
FAB onPressed → _showAddPatientDialog()
        ↓
showDialog hiện AlertDialog
        ↓
User điền thông tin → bấm Lưu
        ↓
_submitAddPatient() chạy
        ↓
PatientService.addPatient() ghi lên Firestore
        ↓
Navigator.pop → đóng dialog
        ↓
Firestore có thay đổi → Stream tự đẩy data mới
        ↓
StreamBuilder rebuild → ListView thêm card mới

3. Bấm vào card bệnh nhân:
_PatientCard onTap
        ↓
Navigator.push → mở EcgRecordingScreen
        ↓
(BenhNhanTab vẫn còn trong stack, chỉ bị che)
        ↓
User bấm Back → Navigator.pop
        ↓
Quay lại BenhNhanTab

4. Bấm nút xóa:
IconButton onPressed → _confirmDelete()
        ↓
showDialog hiện AlertDialog xác nhận
        ↓
User bấm Hủy → Navigator.pop(context, false)
        ↓ confirm = false → return, không làm gì

User bấm Xóa → Navigator.pop(context, true)
        ↓ confirm = true
        ↓
PatientService.deletePatient() xóa trên Firestore
        ↓
Firestore có thay đổi → Stream tự đẩy data mới
        ↓
StreamBuilder rebuild → ListView bỏ card đó đi

Tóm lại toàn bộ:
Mở màn hình
    → Stream lắng nghe Firestore liên tục
        → Thêm/Xóa → Firestore thay đổi
            → Stream đẩy data mới
                → StreamBuilder rebuild
                    → ListView cập nhật */

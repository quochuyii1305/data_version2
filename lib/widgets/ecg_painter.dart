import 'package:flutter/material.dart';

class EcgPainter extends CustomPainter {
  final List<double> points; // Mảng chứa dữ liệu điện áp thô
  final Color color;
  EcgPainter({required this.points, this.color = Colors.greenAccent});

  @override
  void paint(Canvas canvas, Size size) {
    // canvas: bức tranh để vẽ, size: kích thước vùng vẽ
    if (points.isEmpty) return;

    final paint =
        Paint() // "Cây bút" dùng để vẽ nét sóng ECG
          ..color = Colors
              .greenAccent // Màu xanh lá
          ..strokeWidth =
              2 // Độ dày nét vẽ là 2 pixel
          ..style = PaintingStyle
              .stroke; // Chỉ vẽ đường viền (không tô kín phần dưới đồ thị)

    final path = Path(); // Quỹ đạo nối các điểm lại để vẽ 1 lần duy nhất

    // FIXED RANGE
    // Cố định dải trục Y để đồ thị không bị giật nhún hoặc bóp nghẹt khi có nhiễu (spike)
    const double minVal = -3.5; // Giới hạn dưới của điện áp
    const double maxVal = 3.5; // Giới hạn trên của điện áp

    final double range =
        maxVal - minVal; // Khoảng cách biên độ tổng (VD: 1.0) dùng để chuẩn hóa

    final double dx =
        size.width /
        (points.length -
            1); // Khoảng cách (pixel) trục X giữa 2 điểm liên tiếp để rải đều màn hình

    for (int i = 0; i < points.length; i++) {
      double value = points[i]; // Lấy giá trị tín hiệu thực tế tại điểm thứ i

      // Normalize (0 → 1)
      double normalized =
          (value - minVal) / range; // Đưa giá trị về tỷ lệ % từ 0.0 đến 1.0

      // Đảo trục Y (vì canvas gốc ở trên)
      double y =
          size.height *
          (1 -
              normalized); // Tọa độ Y. Lấy 1 trừ đi để lật ngược đồ thị (vì Y=0 ở trên cùng)
      double x = i * dx; // Tọa độ X (pixel) = thứ tự điểm * khoảng cách

      if (i == 0) {
        path.moveTo(
          x,
          y,
        ); // Điểm đầu tiên: Nhấc bút và đặt xuống tại tọa độ (x, y)
      } else {
        path.lineTo(
          x,
          y,
        ); // Các điểm sau: Kẻ đường thẳng nối tiếp từ điểm trước đó tới (x, y)
      }
    }

    canvas.drawPath(
      path,
      paint,
    ); // Yêu cầu canvas vẽ toàn bộ quỹ đạo ra màn hình bằng "cây bút" đã tạo

    // ── (Optional) vẽ đường baseline giữa ─────────────────────
    final midPaint =
        Paint() // "Cây bút" phụ để vẽ đường đẳng điện (đường tham chiếu 0)
          ..color = Colors
              .white24 // Màu trắng mờ
          ..strokeWidth = 1; // Nét mảnh 1 pixel

    canvas.drawLine(
      Offset(
        0,
        size.height / 2,
      ), // Điểm bắt đầu (mép trái, chính giữa chiều cao)
      Offset(
        size.width,
        size.height / 2,
      ), // Điểm kết thúc (mép phải, chính giữa chiều cao)
      midPaint, // Dùng bút phụ để vẽ
    );
  }

  @override
  bool shouldRepaint(covariant EcgPainter oldDelegate) {
    return true; // Trả về true để báo cho Flutter vẽ lại frame mới mỗi khi có dữ liệu điểm mới
  }
}

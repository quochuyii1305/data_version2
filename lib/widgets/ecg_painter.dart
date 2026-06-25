import 'package:flutter/material.dart';

class EcgPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final int sampleRateHz;

  // Số mẫu cố định muốn hiển thị trên trục X.
  // Ví dụ 500 mẫu ở 250Hz thì tương ứng 2 giây, tức 2000ms.
  final int visibleSampleCount;

  const EcgPainter({
    required this.points,
    this.color = Colors.greenAccent,
    this.sampleRateHz = 250,
    this.visibleSampleCount = 500,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Padding để chừa chỗ vẽ nhãn trục X và trục Y.
    const double paddingLeft = 45.0;
    const double paddingBottom = 28.0;
    const double paddingTop = 8.0;
    const double paddingRight = 8.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    // Giữ cố định dải điện áp hiển thị trên trục Y.
    const double yMin = 0.0;
    const double yMax = 3.5;
    const double yRange = yMax - yMin;

    // Đổi giá trị ECG sang tọa độ Y trên màn hình.
    double toY(double v) {
      return paddingTop + chartHeight * (1 - (v - yMin) / yRange);
    }

    // Đổi vị trí mẫu sang tọa độ X.
    // Ở đây dùng visibleSampleCount thay vì points.length để trục X đứng im ngay từ đầu.
    double toX(int i) {
      return paddingLeft + chartWidth * i / (visibleSampleCount - 1);
    }

    // Vẽ lưới nền cho đồ thị.
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.5;

    const int yGridCount = 5;
    const int xGridCount = 5;

    for (int i = 0; i <= yGridCount; i++) {
      final y = paddingTop + chartHeight * i / yGridCount;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(paddingLeft + chartWidth, y),
        gridPaint,
      );
    }

    for (int i = 0; i <= xGridCount; i++) {
      final x = paddingLeft + chartWidth * i / xGridCount;
      canvas.drawLine(
        Offset(x, paddingTop),
        Offset(x, paddingTop + chartHeight),
        gridPaint,
      );
    }

    // Vẽ hai trục chính của đồ thị.
    final axisPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, paddingTop + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(paddingLeft, paddingTop + chartHeight),
      Offset(paddingLeft + chartWidth, paddingTop + chartHeight),
      axisPaint,
    );

    // Style chữ cho nhãn trục.
    final labelStyle = TextStyle(
      color: Colors.white54,
      fontSize: 9,
    );

    // Vẽ các mốc điện áp trên trục Y.
    for (int i = 0; i <= yGridCount; i++) {
      final v = yMax - (yRange * i / yGridCount);
      final y = paddingTop + chartHeight * i / yGridCount;
      final str = v.toStringAsFixed(1);

      final tp = TextPainter(
        text: TextSpan(text: str, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(paddingLeft - tp.width - 3, y - tp.height / 2),
      );
    }

    // Vẽ tên trục Y và xoay chữ theo chiều dọc.
    final yTitlePainter = TextPainter(
      text: TextSpan(
        text: 'Amplitude (V)',
        style: TextStyle(color: Colors.white38, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(
      10,
      paddingTop + chartHeight / 2 + yTitlePainter.width / 2,
    );
    canvas.rotate(-3.14159 / 2);
    yTitlePainter.paint(canvas, Offset.zero);
    canvas.restore();

    // Tính khoảng thời gian cố định mà trục X đại diện.
    // Vì dùng visibleSampleCount nên nhãn thời gian không tăng dần theo points.length nữa.
    final double windowMs = visibleSampleCount * 1000.0 / sampleRateHz;

    // Vẽ các mốc thời gian trên trục X.
    for (int i = 0; i <= xGridCount; i++) {
      final ms = (windowMs * i / xGridCount).toInt();
      final str = '$ms';
      final x = paddingLeft + chartWidth * i / xGridCount;

      final tp = TextPainter(
        text: TextSpan(text: str, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(x - tp.width / 2, paddingTop + chartHeight + 4),
      );
    }

    // Vẽ tên trục X.
    final xTitlePainter = TextPainter(
      text: TextSpan(
        text: 'Time (ms)',
        style: TextStyle(color: Colors.white38, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    xTitlePainter.paint(
      canvas,
      Offset(
        paddingLeft + chartWidth / 2 - xTitlePainter.width / 2,
        size.height - xTitlePainter.height,
      ),
    );

    // Vẽ đường sóng ECG.
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(toX(0), toY(points[0]));

    for (int i = 1; i < points.length; i++) {
      if (i >= visibleSampleCount) break;
      path.lineTo(toX(i), toY(points[i]));
    }

    canvas.drawPath(path, linePaint);

    // Vẽ đường baseline ở giữa đồ thị để dễ quan sát dao động ECG.
    canvas.drawLine(
      Offset(paddingLeft, paddingTop + chartHeight / 2),
      Offset(paddingLeft + chartWidth, paddingTop + chartHeight / 2),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant EcgPainter old) {
    return old.points != points ||
        old.color != color ||
        old.sampleRateHz != sampleRateHz ||
        old.visibleSampleCount != visibleSampleCount;
  }
}
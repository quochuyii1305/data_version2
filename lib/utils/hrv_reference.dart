import 'dart:math' as math;

class HrvReferenceRange {
  final double mean;
  final double sd;

  const HrvReferenceRange({required this.mean, required this.sd});

  double get lower => math.max(0, mean - sd);
  double get upper => mean + sd;
}

class HrvMetricResult {
  final String level; // low / normal / high
  final String text;
  final HrvReferenceRange range;

  const HrvMetricResult({
    required this.level,
    required this.text,
    required this.range,
  });
}

class HrvEvaluationResult {
  final int age;
  final String ageGroup;
  final String gender;
  final HrvMetricResult sdnn;
  final HrvMetricResult rmssd;
  final String overall;

  const HrvEvaluationResult({
    required this.age,
    required this.ageGroup,
    required this.gender,
    required this.sdnn,
    required this.rmssd,
    required this.overall,
  });
}

class HrvReference {
  static const int referenceYear = 2026;

  static int? birthYearFromNgaySinh(String? ngaySinh) {
    if (ngaySinh == null || ngaySinh.trim().isEmpty) return null;

    final matches = RegExp(r'\d{4}').allMatches(ngaySinh);
    if (matches.isEmpty) return null;

    final year = int.tryParse(matches.last.group(0)!);
    if (year == null) return null;

    if (year < 1900 || year > referenceYear) return null;
    return year;
  }

  static int? ageFromNgaySinh(String? ngaySinh) {
    final year = birthYearFromNgaySinh(ngaySinh);
    if (year == null) return null;
    return referenceYear - year;
  }

  static String? normalizeGender(String? gioiTinh) {
    final gt = gioiTinh?.trim();
    if (gt == 'Nam') return 'Nam';
    if (gt == 'Nữ') return 'Nữ';
    return null;
  }

  static String ageGroupLabel(int age) {
    if (age <= 29) return '≤ 29';
    if (age <= 39) return '30-39';
    if (age <= 49) return '40-49';
    return '≥ 50';
  }

  static HrvReferenceRange? _range({
    required String gender,
    required int age,
    required String metric,
  }) {
    final ageGroup = ageGroupLabel(age);

    const male = {
      '≤ 29': {
        'sdnn': HrvReferenceRange(mean: 51.88, sd: 57.27),
        'rmssd': HrvReferenceRange(mean: 36.10, sd: 19.18),
      },
      '30–39': {
        'sdnn': HrvReferenceRange(mean: 42.47, sd: 16.68),
        'rmssd': HrvReferenceRange(mean: 31.82, sd: 16.73),
      },
      '40–49': {
        'sdnn': HrvReferenceRange(mean: 38.00, sd: 17.60),
        'rmssd': HrvReferenceRange(mean: 28.22, sd: 17.89),
      },
      '≥ 50': {
        'sdnn': HrvReferenceRange(mean: 32.57, sd: 14.91),
        'rmssd': HrvReferenceRange(mean: 23.21, sd: 16.66),
      },
    };

    const female = {
      '≤ 29': {
        'sdnn': HrvReferenceRange(mean: 44.36, sd: 14.96),
        'rmssd': HrvReferenceRange(mean: 33.88, sd: 15.57),
      },
      '30–39': {
        'sdnn': HrvReferenceRange(mean: 44.70, sd: 27.76),
        'rmssd': HrvReferenceRange(mean: 34.79, sd: 19.24),
      },
      '40–49': {
        'sdnn': HrvReferenceRange(mean: 37.80, sd: 15.60),
        'rmssd': HrvReferenceRange(mean: 30.42, sd: 18.19),
      },
      '≥ 50': {
        'sdnn': HrvReferenceRange(mean: 34.21, sd: 26.40),
        'rmssd': HrvReferenceRange(mean: 27.70, sd: 27.07),
      },
    };

    final table = gender == 'Nam' ? male : female;
    return table[ageGroup]?[metric];
  }

  static String _overallText({
    required HrvMetricResult sdnn,
    required HrvMetricResult rmssd,
  }) {
    final s = sdnn.level;
    final r = rmssd.level;

    if (s == 'normal' && r == 'normal') {
      return 'SDNN và RMSSD trong vùng tham chiếu của nhóm tuổi/giới';
    }

    if (s == 'low' && r == 'low') {
      return 'SDNN và RMSSD đều thấp hơn vùng tham chiếu của nhóm tuổi/giới';
    }

    if (s == 'high' && r == 'high') {
      return 'SDNN và RMSSD đều cao hơn vùng tham chiếu của nhóm tuổi/giới';
    }

    if (s == 'low' && r == 'normal') {
      return 'SDNN thấp hơn vùng tham chiếu, RMSSD trong vùng tham chiếu';
    }

    if (s == 'normal' && r == 'low') {
      return 'RMSSD thấp hơn vùng tham chiếu, SDNN trong vùng tham chiếu';
    }

    if (s == 'high' && r == 'normal') {
      return 'SDNN cao hơn vùng tham chiếu, RMSSD trong vùng tham chiếu';
    }

    if (s == 'normal' && r == 'high') {
      return 'RMSSD cao hơn vùng tham chiếu, SDNN trong vùng tham chiếu';
    }
    if (s == 'low' && r == 'high') {
      return 'SDNN thấp hơn vùng tham chiếu, RMSSD cao hơn vùng tham chiếu. Kết quả lệch khác hướng, nên kiểm tra tín hiệu hoặc đo lại';
    }
    if (s == 'high' && r == 'low') {
      return 'SDNN cao hơn vùng tham chiếu, RMSSD thấp hơn vùng tham chiếu. Kết quả lệch khác hướng, nên kiểm tra tín hiệu hoặc đo lại';
    }
    return 'SDNN và RMSSD lệch khác hướng so với vùng tham chiếu, nên kiểm tra tín hiệu hoặc đo lại';
  }

  static HrvMetricResult _evaluateMetric({
    required double value,
    required HrvReferenceRange range,
  }) {
    if (value < range.lower) {
      return HrvMetricResult(
        level: 'low',
        text: 'Thấp hơn so với độ tuổi',
        range: range,
      );
    }

    if (value > range.upper) {
      return HrvMetricResult(
        level: 'high',
        text: 'Cao hơn so với độ tuổi',
        range: range,
      );
    }

    return HrvMetricResult(
      level: 'normal',
      text: 'Bình thường so với độ tuổi',
      range: range,
    );
  }

  static HrvEvaluationResult? evaluate({
    required double? sdnn,
    required double? rmssd,
    required String? gioiTinh,
    required String? ngaySinh,
  }) {
    if (sdnn == null || rmssd == null) return null;

    final gender = normalizeGender(gioiTinh);
    final age = ageFromNgaySinh(ngaySinh);

    if (gender == null || age == null) return null;

    final sdnnRange = _range(gender: gender, age: age, metric: 'sdnn');
    final rmssdRange = _range(gender: gender, age: age, metric: 'rmssd');

    if (sdnnRange == null || rmssdRange == null) return null;

    final sdnnEval = _evaluateMetric(value: sdnn, range: sdnnRange);
    final rmssdEval = _evaluateMetric(value: rmssd, range: rmssdRange);

    final overall = _overallText(sdnn: sdnnEval, rmssd: rmssdEval);

    return HrvEvaluationResult(
      age: age,
      ageGroup: ageGroupLabel(age),
      gender: gender,
      sdnn: sdnnEval,
      rmssd: rmssdEval,
      overall: overall,
    );
  }
}

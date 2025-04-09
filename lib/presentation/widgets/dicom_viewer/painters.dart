import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 측정 도구 페인터
class MeasurementPainter extends CustomPainter {
  final List<Offset> points;
  final String distanceText;
  final Color color;
  final double strokeWidth;

  MeasurementPainter({
    required this.points,
    required this.distanceText,
    this.color = Colors.yellow,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final dotPaint =
        Paint()
          ..color = color
          ..strokeWidth = 1
          ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 측정 포인트 그리기
    for (var point in points) {
      // 포인트 위치에 작은 십자가 그리기
      canvas.drawCircle(point, 5, paint);
      canvas.drawLine(
        Offset(point.dx - 8, point.dy),
        Offset(point.dx + 8, point.dy),
        paint,
      );
      canvas.drawLine(
        Offset(point.dx, point.dy - 8),
        Offset(point.dx, point.dy + 8),
        paint,
      );

      // 포인트 위치에 작은 원 그리기
      canvas.drawCircle(point, 2, dotPaint);
    }

    // 두 점 사이에 선 그리기
    if (points.length == 2) {
      canvas.drawLine(points[0], points[1], paint);

      // 중간 지점 계산
      final midPoint = Offset(
        (points[0].dx + points[1].dx) / 2,
        (points[0].dy + points[1].dy) / 2,
      );

      // 거리 표시를 위한 배경 그리기
      final textBackground =
          Paint()
            ..color = Colors.black.withOpacity(0.7)
            ..style = PaintingStyle.fill;

      // 텍스트 측정
      textPainter.text = TextSpan(
        text: distanceText,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.layout();

      // 텍스트 배경 그리기
      final textRect = Rect.fromCenter(
        center: midPoint,
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(textRect, const Radius.circular(4)),
        textBackground,
      );

      // 텍스트 그리기
      textPainter.paint(
        canvas,
        midPoint - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(MeasurementPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.distanceText != distanceText ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// 주석 페인터
class AnnotationPainter extends CustomPainter {
  final List<Map<String, dynamic>> annotations;

  AnnotationPainter({required this.annotations});

  @override
  void paint(Canvas canvas, Size size) {
    for (var annotation in annotations) {
      final point = annotation['position'] as Offset;
      final text = annotation['text'] as String;
      final color = annotation['color'] as Color? ?? Colors.green;

      // 주석 마커와 텍스트 그리기
      _drawAnnotation(canvas, point, text, color);
    }
  }

  void _drawAnnotation(Canvas canvas, Offset point, String text, Color color) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final fillPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // 주석 위치에 마커 그리기 (작은 원)
    canvas.drawCircle(point, 6, paint);
    canvas.drawCircle(point, 3, fillPaint);

    // 주석 텍스트 그리기
    final textBackground =
        Paint()
          ..color = Colors.black.withOpacity(0.7)
          ..style = PaintingStyle.fill;

    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: 14),
    );

    textPainter.layout(maxWidth: 200);

    // 텍스트를 표시할 위치 계산 (마커 옆)
    final textOffset = Offset(point.dx + 15, point.dy - textPainter.height / 2);

    // 텍스트 배경 그리기
    final textRect = Rect.fromLTWH(
      textOffset.dx - 4,
      textOffset.dy - 4,
      textPainter.width + 8,
      textPainter.height + 8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(textRect, const Radius.circular(4)),
      textBackground,
    );

    // 텍스트 그리기
    textPainter.paint(canvas, textOffset);

    // 마커와 텍스트를 연결하는 선
    canvas.drawLine(
      point,
      Offset(textOffset.dx - 4, textOffset.dy + textPainter.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations;
  }
}

/// 각도 측정 페인터
class AngleMeasurementPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  AngleMeasurementPainter({required this.points, this.color = Colors.orange});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 3) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final fillPaint =
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    // 세 점 연결
    final path =
        Path()
          ..moveTo(points[0].dx, points[0].dy)
          ..lineTo(points[1].dx, points[1].dy)
          ..lineTo(points[2].dx, points[2].dy);

    canvas.drawPath(path, paint);

    // 각 점에 마커 표시
    for (var point in points) {
      canvas.drawCircle(point, 5, paint);
      canvas.drawCircle(point, 2, Paint()..color = color);
    }

    // 각도 계산
    final angle = _calculateAngle(points[0], points[1], points[2]);

    // 각도 호 그리기
    _drawAngleArc(
      canvas,
      points[1],
      points[0],
      points[2],
      angle,
      paint,
      fillPaint,
    );

    // 각도 텍스트 표시
    _drawAngleText(canvas, points[1], points[0], points[2], angle);
  }

  // 각도 계산 (라디안)
  double _calculateAngle(Offset p1, Offset p2, Offset p3) {
    final vector1 = Offset(p1.dx - p2.dx, p1.dy - p2.dy);
    final vector2 = Offset(p3.dx - p2.dx, p3.dy - p2.dy);

    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    final magnitude1 = math.sqrt(
      vector1.dx * vector1.dx + vector1.dy * vector1.dy,
    );
    final magnitude2 = math.sqrt(
      vector2.dx * vector2.dx + vector2.dy * vector2.dy,
    );

    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    return math.acos(cosAngle.clamp(-1.0, 1.0));
  }

  // 각도 호 그리기
  void _drawAngleArc(
    Canvas canvas,
    Offset vertex,
    Offset p1,
    Offset p2,
    double angle,
    Paint linePaint,
    Paint fillPaint,
  ) {
    // 반지름 (두 선의 길이의 10% 정도)
    final dist1 = (p1 - vertex).distance;
    final dist2 = (p2 - vertex).distance;
    final radius = math.min(dist1, dist2) * 0.2;

    // 첫 번째 선의 각도
    final startAngle = math.atan2(p1.dy - vertex.dy, p1.dx - vertex.dx);

    // 호 그리기
    final rect = Rect.fromCircle(center: vertex, radius: radius);
    canvas.drawArc(rect, startAngle, angle, true, fillPaint);
    canvas.drawArc(rect, startAngle, angle, false, linePaint);
  }

  // 각도 텍스트 표시
  void _drawAngleText(
    Canvas canvas,
    Offset vertex,
    Offset p1,
    Offset p2,
    double angle,
  ) {
    // 각도 텍스트 (도 단위)
    final angleDegrees = (angle * 180 / math.pi).toStringAsFixed(1);

    // 텍스트 위치 계산 (호의 중간 지점)
    final startAngle = math.atan2(p1.dy - vertex.dy, p1.dx - vertex.dx);
    final midAngle = startAngle + angle / 2;
    final radius =
        math.min((p1 - vertex).distance, (p2 - vertex).distance) * 0.3;

    final textPosition = Offset(
      vertex.dx + radius * math.cos(midAngle),
      vertex.dy + radius * math.sin(midAngle),
    );

    // 텍스트 그리기
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$angleDegrees°',
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black.withOpacity(0.5),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // 텍스트 배경
    final padding = 4.0;
    final backgroundRect = Rect.fromCenter(
      center: textPosition,
      width: textPainter.width + padding * 2,
      height: textPainter.height + padding * 2,
    );

    canvas.drawRect(
      backgroundRect,
      Paint()..color = Colors.black.withOpacity(0.7),
    );

    textPainter.paint(
      canvas,
      textPosition - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(AngleMeasurementPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

/// 영역 측정 페인터 (사각형, 타원)
class AreaMeasurementPainter extends CustomPainter {
  final List<Offset> points;
  final String measurementText;
  final String areaType; // 'rectangle' 또는 'ellipse'
  final Color color;

  AreaMeasurementPainter({
    required this.points,
    required this.measurementText,
    required this.areaType,
    this.color = Colors.lightBlue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final fillPaint =
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    // 사각형 또는 타원 그리기
    final rect = Rect.fromPoints(points[0], points[1]);

    if (areaType == 'rectangle') {
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, paint);
    } else if (areaType == 'ellipse') {
      canvas.drawOval(rect, fillPaint);
      canvas.drawOval(rect, paint);
    }

    // 모서리에 점 그리기
    for (var point in points) {
      canvas.drawCircle(point, 4, paint);
    }

    // 크기 텍스트 표시
    final textPainter = TextPainter(
      text: TextSpan(
        text: measurementText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black.withOpacity(0.5),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // 텍스트 위치 (영역의 중심)
    final textPosition = rect.center;

    // 텍스트 배경
    final padding = 4.0;
    final backgroundRect = Rect.fromCenter(
      center: textPosition,
      width: textPainter.width + padding * 2,
      height: textPainter.height + padding * 2,
    );

    canvas.drawRect(
      backgroundRect,
      Paint()..color = Colors.black.withOpacity(0.7),
    );

    textPainter.paint(
      canvas,
      textPosition - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(AreaMeasurementPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.measurementText != measurementText ||
        oldDelegate.areaType != areaType ||
        oldDelegate.color != color;
  }
}

/// 자유 곡선 그리기 페인터
class FreehandDrawingPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  FreehandDrawingPainter({
    required this.points,
    this.color = Colors.redAccent,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FreehandDrawingPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

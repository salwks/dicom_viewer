import 'package:flutter/material.dart';

/// 측정 도구 페인터
class MeasurementPainter extends CustomPainter {
  final List<Offset> points;
  final double distance;

  MeasurementPainter({required this.points, required this.distance});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 측정 포인트 그리기
    for (var point in points) {
      // 포인트 위치에 작은 원 그리기
      canvas.drawCircle(point, 5, paint);
    }

    // 두 점 사이에 선 그리기
    if (points.length == 2) {
      canvas.drawLine(points[0], points[1], paint);

      // 중간 지점 계산
      final midPoint = Offset(
        (points[0].dx + points[1].dx) / 2,
        (points[0].dy + points[1].dy) / 2,
      );

      // 거리 표시
      textPainter.text = TextSpan(
        text: '${distance.toStringAsFixed(1)} px',
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 14,
          backgroundColor: Colors.black54,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        midPoint - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(MeasurementPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.distance != distance;
  }
}

/// 주석 페인터
class AnnotationPainter extends CustomPainter {
  final List<Map<String, dynamic>> annotations;

  AnnotationPainter({required this.annotations});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.green
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // 각 주석 그리기
    for (var annotation in annotations) {
      final point = annotation['position'] as Offset;
      final text = annotation['text'] as String;

      // 주석 위치에 마커 그리기
      canvas.drawCircle(point, 5, paint);

      // 주석 텍스트 그리기
      final textBackground =
          Paint()
            ..color = Colors.black.withOpacity(0.6)
            ..style = PaintingStyle.fill;

      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );

      textPainter.layout(maxWidth: size.width - point.dx - 20);

      // 텍스트 배경 그리기
      final textRect = Rect.fromLTWH(
        point.dx + 10,
        point.dy - 10,
        textPainter.width + 8,
        textPainter.height + 8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(textRect, const Radius.circular(4)),
        textBackground,
      );

      // 텍스트 그리기
      textPainter.paint(canvas, point + const Offset(14, -6));

      // 마커와 텍스트를 연결하는 선
      canvas.drawLine(point, Offset(point.dx + 10, point.dy), paint);
    }
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations;
  }
}

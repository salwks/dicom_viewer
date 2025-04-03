import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/measurement_utils.dart';

/// 측정 도구 타입 정의
enum MeasurementType {
  distance, // 거리 측정
  angle, // 각도 측정
  rectangle, // 사각형 영역 측정
  ellipse, // 타원 영역 측정
  freehand, // 자유 곡선 측정
}

/// 측정 도구 페인터
class MeasurementPainter extends CustomPainter {
  final List<Offset> points;
  final MeasurementType type;
  final double? value; // 측정값 (거리, 각도, 면적 등)
  final double? secondaryValue; // 보조 측정값 (둘레 등)
  final Color measurementColor; // 측정 도구 색상
  final double strokeWidth; // 선 두께

  MeasurementPainter({
    required this.points,
    required this.type,
    this.value,
    this.secondaryValue,
    this.measurementColor = Colors.yellow,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = measurementColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final dotPaint =
        Paint()
          ..color = measurementColor
          ..strokeWidth = 1
          ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 각 측정 포인트 그리기
    for (var point in points) {
      canvas.drawCircle(point, 5, dotPaint);
    }

    // 측정 타입에 따른 그리기
    switch (type) {
      case MeasurementType.distance:
        _drawDistanceMeasurement(canvas, paint, textPainter);
        break;
      case MeasurementType.angle:
        _drawAngleMeasurement(canvas, paint, textPainter);
        break;
      case MeasurementType.rectangle:
        _drawRectangleMeasurement(canvas, paint, textPainter);
        break;
      case MeasurementType.ellipse:
        _drawEllipseMeasurement(canvas, paint, textPainter);
        break;
      case MeasurementType.freehand:
        _drawFreehandMeasurement(canvas, paint, textPainter);
        break;
    }
  }

  // 거리 측정 그리기
  void _drawDistanceMeasurement(
    Canvas canvas,
    Paint paint,
    TextPainter textPainter,
  ) {
    if (points.length >= 2) {
      final p1 = points[0];
      final p2 = points[1];

      // 두 점 사이에 선 그리기
      canvas.drawLine(p1, p2, paint);

      // 중간 지점 계산
      final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

      // 거리 표시
      _drawMeasurementText(
        canvas,
        textPainter,
        midPoint,
        '${value?.toStringAsFixed(1) ?? "?"} px',
      );
    }
  }

  // 각도 측정 그리기
  void _drawAngleMeasurement(
    Canvas canvas,
    Paint paint,
    TextPainter textPainter,
  ) {
    if (points.length >= 3) {
      final p1 = points[0]; // 첫 번째 점
      final p2 = points[1]; // 각도의 정점 (중심점)
      final p3 = points[2]; // 세 번째 점

      // 세 점을 잇는 두 선분 그리기
      canvas.drawLine(p1, p2, paint);
      canvas.drawLine(p2, p3, paint);

      // 각도 표시 위치 계산
      final textPosition = Offset(
        (p1.dx + p2.dx + p3.dx) / 3,
        (p1.dy + p2.dy + p3.dy) / 3,
      );

      // 호 그리기 (각도 표시)
      _drawAngleArc(canvas, p1, p2, p3, paint);

      // 각도 텍스트 표시
      _drawMeasurementText(
        canvas,
        textPainter,
        textPosition,
        '${value?.toStringAsFixed(1) ?? "?"}\u00B0',
      );
    }
  }

  // 각도 호 그리기
  void _drawAngleArc(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Offset p3,
    Paint paint,
  ) {
    // 벡터 계산
    final v1 = p1 - p2;
    final v2 = p3 - p2;

    // 벡터 정규화
    final v1Normalized = v1 / v1.distance;
    final v2Normalized = v2 / v2.distance;

    // 각도 계산
    final angle = MeasurementUtils.calculateAngleInRadians(p1, p2, p3);

    // 시작 각도 계산
    final startAngle = math.atan2(v1.dy, v1.dx);

    // 호 반지름
    final radius = math.min(v1.distance, v2.distance) * 0.3;

    // 호 그리기
    canvas.drawArc(
      Rect.fromCircle(center: p2, radius: radius),
      startAngle,
      angle,
      false,
      paint,
    );
  }

  // 사각형 측정 그리기
  void _drawRectangleMeasurement(
    Canvas canvas,
    Paint paint,
    TextPainter textPainter,
  ) {
    if (points.length >= 2) {
      final p1 = points[0];
      final p2 = points[1];

      // 사각형 그리기
      final rect = Rect.fromPoints(p1, p2);
      canvas.drawRect(rect, paint);

      // 텍스트 위치 (사각형 중앙)
      final textPosition = rect.center;

      // 면적 텍스트 표시
      _drawMeasurementText(
        canvas,
        textPainter,
        textPosition,
        'A: ${value?.toStringAsFixed(1) ?? "?"} px²\nP: ${secondaryValue?.toStringAsFixed(1) ?? "?"} px',
      );
    }
  }

  // 타원 측정 그리기
  void _drawEllipseMeasurement(
    Canvas canvas,
    Paint paint,
    TextPainter textPainter,
  ) {
    if (points.length >= 2) {
      final center = points[0];
      final edge = points[1];

      // 반지름 계산
      final radiusX = (center.dx - edge.dx).abs();
      final radiusY = (center.dy - edge.dy).abs();

      // 타원 그리기
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
        paint,
      );

      // 텍스트 위치 (타원 중앙)
      final textPosition = center;

      // 면적 텍스트 표시
      _drawMeasurementText(
        canvas,
        textPainter,
        textPosition,
        'A: ${value?.toStringAsFixed(1) ?? "?"} px²\nP: ${secondaryValue?.toStringAsFixed(1) ?? "?"} px',
      );
    }
  }

  // 자유 곡선 측정 그리기
  void _drawFreehandMeasurement(
    Canvas canvas,
    Paint paint,
    TextPainter textPainter,
  ) {
    if (points.length >= 2) {
      // 자유 곡선 그리기
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, paint);

      // 폐곡선인 경우 영역 표시
      if (points.length > 2 && (points.first - points.last).distance < 20) {
        // 시작점과 끝점이 가까우면 폐곡선으로 처리

        // 영역 계산을 위해 경로 닫기
        path.close();

        // 채우기용 페인트 (반투명)
        final fillPaint =
            Paint()
              ..color = measurementColor.withOpacity(0.2)
              ..style = PaintingStyle.fill;

        canvas.drawPath(path, fillPaint);

        // 중심점 계산
        double sumX = 0, sumY = 0;
        for (var point in points) {
          sumX += point.dx;
          sumY += point.dy;
        }
        final centerX = sumX / points.length;
        final centerY = sumY / points.length;

        // 면적 텍스트 표시
        _drawMeasurementText(
          canvas,
          textPainter,
          Offset(centerX, centerY),
          'A: ${value?.toStringAsFixed(1) ?? "?"} px²',
        );
      } else {
        // 열린 곡선인 경우 길이 표시
        if (points.length > 1) {
          _drawMeasurementText(
            canvas,
            textPainter,
            points[points.length ~/ 2],
            'L: ${value?.toStringAsFixed(1) ?? "?"} px',
          );
        }
      }
    }
  }

  // 측정 텍스트 그리기
  void _drawMeasurementText(
    Canvas canvas,
    TextPainter textPainter,
    Offset position,
    String text,
  ) {
    // 배경 페인트
    final bgPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.7)
          ..style = PaintingStyle.fill;

    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    textPainter.layout();

    // 배경 그리기
    final bgRect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 16,
      height: textPainter.height + 8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(4)),
      bgPaint,
    );

    // 텍스트 그리기
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(MeasurementPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.type != type ||
        oldDelegate.value != value ||
        oldDelegate.secondaryValue != secondaryValue ||
        oldDelegate.measurementColor != measurementColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// 주석 페인터
class AnnotationPainter extends CustomPainter {
  final List<Map<String, dynamic>> annotations;
  final Color annotationColor;

  AnnotationPainter({
    required this.annotations,
    this.annotationColor = Colors.green,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = annotationColor
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
      final annotType = annotation['type'] as String? ?? 'text';

      // 주석 유형에 따라 다르게 그리기
      switch (annotType) {
        case 'arrow':
          _drawArrowAnnotation(canvas, paint, point, annotation);
          break;
        case 'marker':
          _drawMarkerAnnotation(canvas, paint, point, annotation);
          break;
        case 'rectangle':
          _drawRectangleAnnotation(canvas, paint, point, annotation);
          break;
        case 'text':
        default:
          _drawTextAnnotation(canvas, paint, textPainter, point, text);
          break;
      }
    }
  }

  // 텍스트 주석 그리기
  void _drawTextAnnotation(
    Canvas canvas,
    Paint paint,
    TextPainter textPainter,
    Offset point,
    String text,
  ) {
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

    textPainter.layout(maxWidth: 200); // 최대 너비 지정

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

  // 화살표 주석 그리기
  void _drawArrowAnnotation(
    Canvas canvas,
    Paint paint,
    Offset start,
    Map<String, dynamic> annotation,
  ) {
    final end = annotation['endPoint'] as Offset? ?? start + Offset(50, 0);
    final text = annotation['text'] as String? ?? '';

    // 화살표 선 그리기
    canvas.drawLine(start, end, paint);

    // 화살표 머리 그리기
    _drawArrowHead(canvas, paint, start, end);

    // 텍스트가 있으면 표시
    if (text.isNotEmpty) {
      // 텍스트 페인터 설정
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: paint.color,
            fontSize: 14,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      // 화살표 중간에 텍스트 표시
      final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

      textPainter.paint(
        canvas,
        midPoint - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  // 화살표 머리 그리기
  void _drawArrowHead(Canvas canvas, Paint paint, Offset start, Offset end) {
    // 화살표 방향 벡터
    final direction = end - start;
    final length = direction.distance;

    if (length < 1) return; // 길이가 너무 짧으면 그리지 않음

    // 단위 벡터
    final unitVector = direction / length;

    // 화살표 머리 크기
    final headLength = math.min(15.0, length / 3);

    // 화살표 머리 각도
    final angle = math.pi / 6; // 30도

    // 화살표 머리 양쪽 끝 계산
    final leftPoint =
        end -
        Offset(
              unitVector.dx * math.cos(angle) - unitVector.dy * math.sin(angle),
              unitVector.dx * math.sin(angle) + unitVector.dy * math.cos(angle),
            ) *
            headLength;

    final rightPoint =
        end -
        Offset(
              unitVector.dx * math.cos(-angle) -
                  unitVector.dy * math.sin(-angle),
              unitVector.dx * math.sin(-angle) +
                  unitVector.dy * math.cos(-angle),
            ) *
            headLength;

    // 화살표 머리 그리기
    canvas.drawLine(end, leftPoint, paint);
    canvas.drawLine(end, rightPoint, paint);
  }

  // 마커 주석 그리기
  void _drawMarkerAnnotation(
    Canvas canvas,
    Paint paint,
    Offset point,
    Map<String, dynamic> annotation,
  ) {
    final text = annotation['text'] as String? ?? '';
    final markerType = annotation['markerType'] as String? ?? 'circle';
    final markerSize = annotation['markerSize'] as double? ?? 10.0;

    // 마커 유형에 따라 다르게 그리기
    switch (markerType) {
      case 'square':
        canvas.drawRect(
          Rect.fromCenter(
            center: point,
            width: markerSize * 2,
            height: markerSize * 2,
          ),
          paint,
        );
        break;
      case 'cross':
        canvas.drawLine(
          point - Offset(markerSize, markerSize),
          point + Offset(markerSize, markerSize),
          paint,
        );
        canvas.drawLine(
          point - Offset(markerSize, -markerSize),
          point + Offset(markerSize, -markerSize),
          paint,
        );
        break;
      case 'star':
        _drawStar(canvas, paint, point, markerSize);
        break;
      case 'circle':
      default:
        canvas.drawCircle(point, markerSize, paint);
        break;
    }

    // 텍스트가 있으면 표시
    if (text.isNotEmpty) {
      // 텍스트 페인터 설정
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      // 마커 아래에 텍스트 표시
      textPainter.paint(
        canvas,
        point + Offset(-textPainter.width / 2, markerSize + 5),
      );
    }
  }

  // 별 모양 마커 그리기
  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    final double halfRadius = radius / 2;

    for (int i = 0; i < 5; i++) {
      final outerAngle = -math.pi / 2 + i * 2 * math.pi / 5;
      final innerAngle = outerAngle + math.pi / 5;

      final outerX = center.dx + radius * math.cos(outerAngle);
      final outerY = center.dy + radius * math.sin(outerAngle);
      final innerX = center.dx + halfRadius * math.cos(innerAngle);
      final innerY = center.dy + halfRadius * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }

      path.lineTo(innerX, innerY);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  // 사각형 주석 그리기
  void _drawRectangleAnnotation(
    Canvas canvas,
    Paint paint,
    Offset topLeft,
    Map<String, dynamic> annotation,
  ) {
    final bottomRight =
        annotation['bottomRight'] as Offset? ?? topLeft + Offset(100, 50);
    final text = annotation['text'] as String? ?? '';

    // 사각형 그리기
    canvas.drawRect(Rect.fromPoints(topLeft, bottomRight), paint);

    // 텍스트가 있으면 표시
    if (text.isNotEmpty) {
      // 배경 페인트
      final bgPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.6)
            ..style = PaintingStyle.fill;

      // 텍스트 페인터 설정
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      // 사각형 중앙에 텍스트 표시
      final textPos = Offset(
        (topLeft.dx + bottomRight.dx) / 2 - textPainter.width / 2,
        (topLeft.dy + bottomRight.dy) / 2 - textPainter.height / 2,
      );

      // 텍스트 배경 그리기
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            textPos.dx - 4,
            textPos.dy - 4,
            textPainter.width + 8,
            textPainter.height + 8,
          ),
          const Radius.circular(4),
        ),
        bgPaint,
      );

      // 텍스트 그리기
      textPainter.paint(canvas, textPos);
    }
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.annotationColor != annotationColor;
  }
}

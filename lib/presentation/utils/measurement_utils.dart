import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 측정 유틸리티 클래스
/// 다양한 측정 계산을 위한 정적 메서드 제공
class MeasurementUtils {
  /// 두 점 사이의 유클리드 거리 계산
  static double calculateDistance(Offset p1, Offset p2) {
    return (p1 - p2).distance;
  }

  /// 세 점으로 이루어진 각도 계산 (라디안)
  /// p2가 중심점(정점)
  static double calculateAngleInRadians(Offset p1, Offset p2, Offset p3) {
    // 벡터 계산
    final vector1 = Offset(p1.dx - p2.dx, p1.dy - p2.dy);
    final vector2 = Offset(p3.dx - p2.dx, p3.dy - p2.dy);

    // 벡터의 크기
    final magnitude1 = math.sqrt(
      vector1.dx * vector1.dx + vector1.dy * vector1.dy,
    );
    final magnitude2 = math.sqrt(
      vector2.dx * vector2.dx + vector2.dy * vector2.dy,
    );

    // 0으로 나누기 방지
    if (magnitude1 == 0 || magnitude2 == 0) return 0;

    // 내적 계산
    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;

    // 코사인 값
    double cosAngle = dotProduct / (magnitude1 * magnitude2);

    // 정밀도 문제로 인한 범위 초과 방지 (-1 ~ 1 범위로 제한)
    cosAngle = cosAngle.clamp(-1.0, 1.0);

    return math.acos(cosAngle);
  }

  /// 세 점으로 이루어진 각도 계산 (도)
  static double calculateAngleInDegrees(Offset p1, Offset p2, Offset p3) {
    return calculateAngleInRadians(p1, p2, p3) * 180 / math.pi;
  }

  /// 사각형 영역의 넓이 계산
  static double calculateRectangleArea(Offset p1, Offset p2) {
    final width = (p1.dx - p2.dx).abs();
    final height = (p1.dy - p2.dy).abs();
    return width * height;
  }

  /// 사각형 영역의 둘레 계산
  static double calculateRectanglePerimeter(Offset p1, Offset p2) {
    final width = (p1.dx - p2.dx).abs();
    final height = (p1.dy - p2.dy).abs();
    return 2 * (width + height);
  }

  /// 타원 영역의 넓이 계산
  static double calculateEllipseArea(Offset center, Offset edge) {
    final a = (center.dx - edge.dx).abs(); // 가로 반지름
    final b = (center.dy - edge.dy).abs(); // 세로 반지름
    return math.pi * a * b;
  }

  /// 타원 둘레 계산 (근사값)
  static double calculateEllipsePerimeter(Offset center, Offset edge) {
    final a = (center.dx - edge.dx).abs(); // 가로 반지름
    final b = (center.dy - edge.dy).abs(); // 세로 반지름

    // 람베의 공식을 사용한 타원 둘레 근사값
    final h = math.pow(a - b, 2) / math.pow(a + b, 2);
    return math.pi * (a + b) * (1 + (3 * h) / (10 + math.sqrt(4 - 3 * h)));
  }

  /// 다각형 영역의 넓이 계산 (신발끈 공식)
  static double calculatePolygonArea(List<Offset> points) {
    if (points.length < 3) return 0;

    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].dx * points[j].dy;
      area -= points[j].dx * points[i].dy;
    }

    return (area.abs() / 2);
  }

  /// 픽셀 단위를 물리적 단위로 변환 (예: mm)
  /// pixelSpacing은 DICOM 파일의 픽셀 간격 (mm/pixel)
  static double pixelsToPhysicalUnit(double pixels, double pixelSpacing) {
    return pixels * pixelSpacing;
  }

  /// HU(Hounsfield Unit) 계산
  /// pixel: 이미지의 픽셀 값, rescaleSlope/rescaleIntercept: DICOM 태그에서 가져온 값
  static double calculateHU(
    int pixel,
    double rescaleSlope,
    double rescaleIntercept,
  ) {
    return pixel * rescaleSlope + rescaleIntercept;
  }

  /// 이미지 좌표를 DICOM 좌표로 변환
  static Offset imageToDicomCoordinates(
    Offset imageCoord,
    Size imageSize,
    double zoomFactor,
    Offset panOffset,
  ) {
    // 줌과 패닝을 고려한 좌표 변환
    final adjustedX = (imageCoord.dx - panOffset.dx) / zoomFactor;
    final adjustedY = (imageCoord.dy - panOffset.dy) / zoomFactor;

    // 이미지 크기 내에서 좌표 클램핑
    final clampedX = adjustedX.clamp(0.0, imageSize.width);
    final clampedY = adjustedY.clamp(0.0, imageSize.height);

    return Offset(clampedX, clampedY);
  }
}

import 'package:flutter/material.dart';
import '../../utils/measurement_utils.dart';
import '../dicom_viewer/painters.dart';

/// 측정 관리자 클래스
/// 측정 도구의 상태를 관리하고 측정 값 계산을 담당
class MeasurementManager {
  // 현재 선택된 측정 도구 타입
  MeasurementType _currentType = MeasurementType.distance;

  // 측정 포인트 목록
  List<Offset> _points = [];

  // 임시 포인트 (마우스 드래그 또는 손가락 움직임에 따른 임시 포인트)
  Offset? _tempPoint;

  // 측정 도구 색상
  Color _measurementColor = Colors.yellow;

  // 측정이 활성화되었는지 여부
  bool _isActive = false;

  // 측정 완료 여부
  bool _isCompleted = false;

  // 측정 도구별 필요한 포인트 개수
  final Map<MeasurementType, int> _requiredPoints = {
    MeasurementType.distance: 2,
    MeasurementType.angle: 3,
    MeasurementType.rectangle: 2,
    MeasurementType.ellipse: 2,
    MeasurementType.freehand: 0, // 자유 곡선은 가변적인 포인트 개수
  };

  // Getters
  MeasurementType get currentType => _currentType;
  List<Offset> get points => _points;
  Offset? get tempPoint => _tempPoint;
  Color get measurementColor => _measurementColor;
  bool get isActive => _isActive;
  bool get isCompleted => _isCompleted;

  // 현재 측정 도구에 필요한 포인트 개수
  int get requiredPointCount => _requiredPoints[_currentType] ?? 0;

  // 측정 도구 타입 설정
  void setMeasurementType(MeasurementType type) {
    _currentType = type;
    reset();
  }

  // 측정 도구 색상 설정
  void setMeasurementColor(Color color) {
    _measurementColor = color;
  }

  // 측정 활성화/비활성화
  void setActive(bool active) {
    _isActive = active;
    if (!active) {
      reset();
    }
  }

  // 측정 포인트 추가
  void addPoint(Offset point) {
    if (!_isActive) return;

    // 자유 곡선인 경우 계속해서 포인트 추가
    if (_currentType == MeasurementType.freehand) {
      _points.add(point);
      return;
    }

    // 필요한 포인트 개수까지만 추가
    if (_points.length < requiredPointCount) {
      _points.add(point);

      // 필요한 포인트 개수에 도달하면 측정 완료
      if (_points.length == requiredPointCount) {
        _isCompleted = true;
      }
    } else {
      // 포인트 개수가 이미 충분하면 측정 초기화 후 새 포인트 추가
      reset();
      _points.add(point);
    }
  }

  // 임시 포인트 설정 (마우스 이동 또는 터치 이동에 따른 미리보기용)
  void setTempPoint(Offset? point) {
    _tempPoint = point;
  }

  // 측정 초기화
  void reset() {
    _points = [];
    _tempPoint = null;
    _isCompleted = false;
  }

  // 측정 완료 (자유 곡선 측정 등에서 사용)
  void complete() {
    if (_currentType == MeasurementType.freehand && _points.length >= 2) {
      _isCompleted = true;
    }
  }

  // 측정값 계산
  Map<String, double> calculateMeasurement() {
    switch (_currentType) {
      case MeasurementType.distance:
        return _calculateDistance();
      case MeasurementType.angle:
        return _calculateAngle();
      case MeasurementType.rectangle:
        return _calculateRectangle();
      case MeasurementType.ellipse:
        return _calculateEllipse();
      case MeasurementType.freehand:
        return _calculateFreehand();
    }
  }

  // 거리 측정값 계산
  Map<String, double> _calculateDistance() {
    if (_points.length < 2) {
      return {'distance': 0};
    }

    final distance = MeasurementUtils.calculateDistance(_points[0], _points[1]);
    return {'distance': distance};
  }

  // 각도 측정값 계산
  Map<String, double> _calculateAngle() {
    if (_points.length < 3) {
      return {'angle': 0};
    }

    final angle = MeasurementUtils.calculateAngleInDegrees(
      _points[0],
      _points[1],
      _points[2],
    );
    return {'angle': angle};
  }

  // 사각형 측정값 계산 (면적 및 둘레)
  Map<String, double> _calculateRectangle() {
    if (_points.length < 2) {
      return {'area': 0, 'perimeter': 0};
    }

    final area = MeasurementUtils.calculateRectangleArea(
      _points[0],
      _points[1],
    );
    final perimeter = MeasurementUtils.calculateRectanglePerimeter(
      _points[0],
      _points[1],
    );
    return {'area': area, 'perimeter': perimeter};
  }

  // 타원 측정값 계산 (면적 및 둘레)
  Map<String, double> _calculateEllipse() {
    if (_points.length < 2) {
      return {'area': 0, 'perimeter': 0};
    }

    final area = MeasurementUtils.calculateEllipseArea(_points[0], _points[1]);
    final perimeter = MeasurementUtils.calculateEllipsePerimeter(
      _points[0],
      _points[1],
    );
    return {'area': area, 'perimeter': perimeter};
  }

  // 자유 곡선 측정값 계산 (길이 또는 면적)
  Map<String, double> _calculateFreehand() {
    if (_points.length < 2) {
      return {'length': 0, 'area': 0};
    }

    // 곡선 길이 계산
    double length = 0;
    for (int i = 0; i < _points.length - 1; i++) {
      length += MeasurementUtils.calculateDistance(_points[i], _points[i + 1]);
    }

    // 폐곡선인 경우 면적도 계산 (시작점과 끝점의 거리가 가까울 때)
    double area = 0;
    if (_points.length > 2 && (_points.first - _points.last).distance < 20) {
      area = MeasurementUtils.calculatePolygonArea(_points);
    }

    return {'length': length, 'area': area};
  }

  // 현재 측정 상태에 기반한 MeasurementPainter 생성
  MeasurementPainter createPainter() {
    // 측정 포인트 목록 생성 (임시 포인트 포함)
    final displayPoints = List<Offset>.from(_points);
    if (_tempPoint != null && _points.isNotEmpty && !_isCompleted) {
      displayPoints.add(_tempPoint!);
    }

    // 측정값 계산
    final measurements = calculateMeasurement();
    double? primaryValue;
    double? secondaryValue;

    switch (_currentType) {
      case MeasurementType.distance:
        primaryValue = measurements['distance'];
        break;
      case MeasurementType.angle:
        primaryValue = measurements['angle'];
        break;
      case MeasurementType.rectangle:
      case MeasurementType.ellipse:
        primaryValue = measurements['area'];
        secondaryValue = measurements['perimeter'];
        break;
      case MeasurementType.freehand:
        primaryValue = measurements['length'];
        secondaryValue = measurements['area'];
        break;
    }

    return MeasurementPainter(
      points: displayPoints,
      type: _currentType,
      value: primaryValue,
      secondaryValue: secondaryValue,
      measurementColor: _measurementColor,
    );
  }
}

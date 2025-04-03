import 'package:flutter/material.dart';
import '../dicom_viewer/painters.dart';

/// 주석 도구 타입
enum AnnotationToolType {
  text, // 텍스트 주석
  arrow, // 화살표 주석
  freehand, // 자유 곡선 주석
  marker, // 마커 주석
  rectangle, // 사각형 주석
}

/// 주석 관리자 클래스
/// 주석 도구의 상태를 관리하고 주석 생성을 담당
class AnnotationManager {
  // 현재 선택된 주석 도구 타입
  AnnotationToolType _currentType = AnnotationToolType.text;

  // 주석 목록
  List<Map<String, dynamic>> _annotations = [];

  // 현재 작업 중인 주석 데이터
  Map<String, dynamic>? _currentAnnotation;

  // 임시 포인트 (마우스 드래그 또는 손가락 움직임에 따른 임시 포인트)
  Offset? _tempPoint;

  // 주석 도구 색상
  Color _annotationColor = Colors.green;

  // 주석 모드가 활성화되었는지 여부
  bool _isActive = false;

  // Getters
  AnnotationToolType get currentType => _currentType;
  List<Map<String, dynamic>> get annotations => _annotations;
  Map<String, dynamic>? get currentAnnotation => _currentAnnotation;
  Offset? get tempPoint => _tempPoint;
  Color get annotationColor => _annotationColor;
  bool get isActive => _isActive;

  // 주석 도구 타입 설정
  void setAnnotationType(AnnotationToolType type) {
    _currentType = type;
    _currentAnnotation = null;
    _tempPoint = null;
  }

  // 주석 도구 색상 설정
  void setAnnotationColor(Color color) {
    _annotationColor = color;
  }

  // 주석 모드 활성화/비활성화
  void setActive(bool active) {
    _isActive = active;
    if (!active) {
      _currentAnnotation = null;
      _tempPoint = null;
    }
  }

  // 주석 시작점 설정 (첫 클릭 또는 터치 시)
  void startAnnotation(Offset position) {
    if (!_isActive) return;

    switch (_currentType) {
      case AnnotationToolType.text:
        _handleTextAnnotation(position);
        break;
      case AnnotationToolType.arrow:
        _currentAnnotation = {
          'position': position,
          'endPoint': position,
          'text': '',
          'type': 'arrow',
          'color': _annotationColor,
        };
        break;
      case AnnotationToolType.freehand:
        _currentAnnotation = {
          'position': position,
          'points': [position],
          'type': 'freehand',
          'color': _annotationColor,
        };
        break;
      case AnnotationToolType.marker:
        _currentAnnotation = {
          'position': position,
          'text': '',
          'type': 'marker',
          'markerType': 'circle',
          'markerSize': 10.0,
          'color': _annotationColor,
        };
        break;
      case AnnotationToolType.rectangle:
        _currentAnnotation = {
          'position': position,
          'bottomRight': position,
          'text': '',
          'type': 'rectangle',
          'color': _annotationColor,
        };
        break;
    }
  }

  // 텍스트 주석 처리
  void _handleTextAnnotation(Offset position) {
    // 텍스트 주석은 바로 텍스트 입력 요청
    _currentAnnotation = {
      'position': position,
      'text': '',
      'type': 'text',
      'color': _annotationColor,
    };

    // 텍스트 주석은 텍스트 입력이 필요하므로 바로 확정하지 않음
  }

  // 주석 진행 (드래그 또는 움직임 중)
  void updateAnnotation(Offset position) {
    if (!_isActive || _currentAnnotation == null) return;

    _tempPoint = position;

    switch (_currentType) {
      case AnnotationToolType.arrow:
        _currentAnnotation!['endPoint'] = position;
        break;
      case AnnotationToolType.freehand:
        (_currentAnnotation!['points'] as List<Offset>).add(position);
        break;
      case AnnotationToolType.rectangle:
        _currentAnnotation!['bottomRight'] = position;
        break;
      case AnnotationToolType.text:
      case AnnotationToolType.marker:
        // 이동 없음
        break;
    }
  }

  // 주석 완료 (마우스 업 또는 터치 종료 시)
  void completeAnnotation(Offset? position) {
    if (!_isActive || _currentAnnotation == null) return;

    if (position != null) {
      updateAnnotation(position);
    }

    // 텍스트 주석은 별도 처리 (텍스트 입력 대화상자 표시)
    if (_currentType == AnnotationToolType.text ||
        _currentType == AnnotationToolType.marker) {
      // 텍스트 입력이 필요하므로 주석 확정은 아직 하지 않음
      // 텍스트 입력 대화상자는 상위 위젯에서 표시
      return;
    }

    // 주석 목록에 추가
    _annotations.add(Map<String, dynamic>.from(_currentAnnotation!));

    // 현재 작업 중인 주석 초기화
    _currentAnnotation = null;
    _tempPoint = null;
  }

  // 텍스트 주석에 텍스트 설정 (대화상자에서 입력 후)
  void setAnnotationText(String text) {
    if (_currentAnnotation != null) {
      _currentAnnotation!['text'] = text;

      // 주석 목록에 추가
      _annotations.add(Map<String, dynamic>.from(_currentAnnotation!));

      // 현재 작업 중인 주석 초기화
      _currentAnnotation = null;
      _tempPoint = null;
    }
  }

  // 주석 취소
  void cancelAnnotation() {
    _currentAnnotation = null;
    _tempPoint = null;
  }

  // 모든 주석 초기화
  void clearAllAnnotations() {
    _annotations = [];
    _currentAnnotation = null;
    _tempPoint = null;
  }

  // 특정 주석 삭제
  void removeAnnotation(int index) {
    if (index >= 0 && index < _annotations.length) {
      _annotations.removeAt(index);
    }
  }

  // 주석 페인터 생성
  AnnotationPainter createPainter() {
    // 모든 주석 목록 생성 (현재 작업 중인 주석 포함)
    final displayAnnotations = List<Map<String, dynamic>>.from(_annotations);

    // 작업 중인 주석이 있으면 추가
    if (_currentAnnotation != null) {
      // 작업 중인 주석의 임시 복사본 생성
      final tempAnnotation = Map<String, dynamic>.from(_currentAnnotation!);

      // 타입별 특수 처리
      if (_currentType == AnnotationToolType.arrow && _tempPoint != null) {
        tempAnnotation['endPoint'] = _tempPoint;
      } else if (_currentType == AnnotationToolType.rectangle &&
          _tempPoint != null) {
        tempAnnotation['bottomRight'] = _tempPoint;
      }

      displayAnnotations.add(tempAnnotation);
    }

    return AnnotationPainter(
      annotations: displayAnnotations,
      annotationColor: _annotationColor,
    );
  }
}

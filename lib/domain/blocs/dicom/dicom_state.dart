import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../data/models/dicom_file.dart';
import '../../../presentation/widgets/dicom_viewer/painters.dart';
import '../../../presentation/widgets/annotation_tools/annotation_manager.dart';

enum DicomStatus { initial, loading, loaded, error }

class DicomState extends Equatable {
  final DicomStatus status;
  final DicomFile? dicomFile;
  final int currentImageIndex;
  final double brightness;
  final double contrast;

  // 측정 도구 관련 상태
  final bool isMeasurementMode;
  final MeasurementType measurementType;
  final Color measurementColor;
  final List<Map<String, dynamic>> measurements;

  // 주석 도구 관련 상태
  final bool isAnnotationMode;
  final AnnotationToolType annotationType;
  final Color annotationColor;
  final List<Map<String, dynamic>> annotations;

  // 이미지 변환 관련 상태
  final int rotation; // 0, 90, 180, 270
  final bool flipHorizontal;
  final bool flipVertical;

  // 오류 메시지
  final String? errorMessage;

  const DicomState({
    this.status = DicomStatus.initial,
    this.dicomFile,
    this.currentImageIndex = 0,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.isMeasurementMode = false,
    this.measurementType = MeasurementType.distance,
    this.measurementColor = Colors.yellow,
    this.measurements = const [],
    this.isAnnotationMode = false,
    this.annotationType = AnnotationToolType.text,
    this.annotationColor = Colors.green,
    this.annotations = const [],
    this.rotation = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.errorMessage,
  });

  DicomState copyWith({
    DicomStatus? status,
    DicomFile? dicomFile,
    int? currentImageIndex,
    double? brightness,
    double? contrast,
    bool? isMeasurementMode,
    MeasurementType? measurementType,
    Color? measurementColor,
    List<Map<String, dynamic>>? measurements,
    bool? isAnnotationMode,
    AnnotationToolType? annotationType,
    Color? annotationColor,
    List<Map<String, dynamic>>? annotations,
    int? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
    String? errorMessage,
  }) {
    return DicomState(
      status: status ?? this.status,
      dicomFile: dicomFile ?? this.dicomFile,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      isMeasurementMode: isMeasurementMode ?? this.isMeasurementMode,
      measurementType: measurementType ?? this.measurementType,
      measurementColor: measurementColor ?? this.measurementColor,
      measurements: measurements ?? this.measurements,
      isAnnotationMode: isAnnotationMode ?? this.isAnnotationMode,
      annotationType: annotationType ?? this.annotationType,
      annotationColor: annotationColor ?? this.annotationColor,
      annotations: annotations ?? this.annotations,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    dicomFile,
    currentImageIndex,
    brightness,
    contrast,
    isMeasurementMode,
    measurementType,
    measurementColor,
    measurements,
    isAnnotationMode,
    annotationType,
    annotationColor,
    annotations,
    rotation,
    flipHorizontal,
    flipVertical,
    errorMessage,
  ];

  // 현재 이미지 가져오기
  DicomImage? get currentImage {
    if (dicomFile == null || dicomFile!.images.isEmpty) {
      return null;
    }

    if (currentImageIndex >= dicomFile!.images.length) {
      return dicomFile!.images.first;
    }

    return dicomFile!.images[currentImageIndex];
  }
}

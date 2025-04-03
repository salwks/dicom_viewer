import 'package:equatable/equatable.dart';
import '../../../data/models/dicom_file.dart';

enum DicomStatus { initial, loading, loaded, error }

class DicomState extends Equatable {
  final DicomStatus status;
  final DicomFile? dicomFile;
  final int currentImageIndex;
  final double brightness;
  final double contrast;
  final bool isMeasurementMode;
  final bool isAnnotationMode;
  final List<Map<String, double>> measurementPoints;
  final List<Map<String, dynamic>> annotations;
  final String? errorMessage;

  const DicomState({
    this.status = DicomStatus.initial,
    this.dicomFile,
    this.currentImageIndex = 0,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.isMeasurementMode = false,
    this.isAnnotationMode = false,
    this.measurementPoints = const [],
    this.annotations = const [],
    this.errorMessage,
  });

  DicomState copyWith({
    DicomStatus? status,
    DicomFile? dicomFile,
    int? currentImageIndex,
    double? brightness,
    double? contrast,
    bool? isMeasurementMode,
    bool? isAnnotationMode,
    List<Map<String, double>>? measurementPoints,
    List<Map<String, dynamic>>? annotations,
    String? errorMessage,
  }) {
    return DicomState(
      status: status ?? this.status,
      dicomFile: dicomFile ?? this.dicomFile,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      isMeasurementMode: isMeasurementMode ?? this.isMeasurementMode,
      isAnnotationMode: isAnnotationMode ?? this.isAnnotationMode,
      measurementPoints: measurementPoints ?? this.measurementPoints,
      annotations: annotations ?? this.annotations,
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
    isAnnotationMode,
    measurementPoints,
    annotations,
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

  // 측정 거리 계산
  double calculateDistance() {
    if (measurementPoints.length != 2) return 0;

    final p1x = measurementPoints[0]['x'] ?? 0;
    final p1y = measurementPoints[0]['y'] ?? 0;
    final p2x = measurementPoints[1]['x'] ?? 0;
    final p2y = measurementPoints[1]['y'] ?? 0;

    return _distance(p1x, p1y, p2x, p2y);
  }

  // 두 점 사이의 거리 계산
  double _distance(double x1, double y1, double x2, double y2) {
    return ((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)) * 0.5;
  }
}

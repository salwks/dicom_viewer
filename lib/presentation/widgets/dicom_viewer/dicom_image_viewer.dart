import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../data/models/dicom_file.dart';
import '../../../data/services/dicom_service.dart';
import '../measurement_tools/measurement_manager.dart';
import '../annotation_tools/annotation_manager.dart';
import 'painters.dart';

class DicomImageViewer extends StatefulWidget {
  final DicomImage dicomImage;
  final double brightness;
  final double contrast;
  final bool isMeasurementMode;
  final bool isAnnotationMode;
  final MeasurementType? measurementType;
  final AnnotationToolType? annotationType;
  final Color measurementColor;
  final Color annotationColor;
  final VoidCallback? onMeasurementComplete;
  final Function(String)? onTextAnnotationRequested;

  const DicomImageViewer({
    super.key,
    required this.dicomImage,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.isMeasurementMode = false,
    this.isAnnotationMode = false,
    this.measurementType,
    this.annotationType,
    this.measurementColor = Colors.yellow,
    this.annotationColor = Colors.green,
    this.onMeasurementComplete,
    this.onTextAnnotationRequested,
  });

  @override
  State<DicomImageViewer> createState() => _DicomImageViewerState();
}

class _DicomImageViewerState extends State<DicomImageViewer>
    with SingleTickerProviderStateMixin {
  // 확대/축소 및 패닝을 위한 변환 매트릭스
  final TransformationController _transformationController =
      TransformationController();

  // 이미지 처리 서비스
  final DicomService _dicomService = DicomService();

  // 측정 및 주석 관리자
  late MeasurementManager _measurementManager;
  late AnnotationManager _annotationManager;

  // 이미지 캐시
  Uint8List? _processedImage;
  double _lastBrightness = 0.0;
  double _lastContrast = 1.0;

  // 애니메이션 컨트롤러 (더블 탭 줌)
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  // 현재 변환 매트릭스 저장 (애니메이션용)
  Matrix4? _homeMatrix;

  @override
  void initState() {
    super.initState();
    _processImage();

    // 측정 및 주석 관리자 초기화
    _measurementManager = MeasurementManager();
    _annotationManager = AnnotationManager();

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animationController.addListener(() {
      if (_animation != null) {
        _transformationController.value = _animation!.value;
      }
    });
  }

  @override
  void didUpdateWidget(DicomImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 밝기나 대비가 변경되면 이미지 다시 처리
    if (oldWidget.brightness != widget.brightness ||
        oldWidget.contrast != widget.contrast ||
        oldWidget.dicomImage != widget.dicomImage) {
      _processImage();
    }

    // 측정 모드 변경
    if (oldWidget.isMeasurementMode != widget.isMeasurementMode) {
      _measurementManager.setActive(widget.isMeasurementMode);
    }

    // 주석 모드 변경
    if (oldWidget.isAnnotationMode != widget.isAnnotationMode) {
      _annotationManager.setActive(widget.isAnnotationMode);
    }

    // 측정 도구 타입 변경
    if (widget.measurementType != null &&
        oldWidget.measurementType != widget.measurementType) {
      _measurementManager.setMeasurementType(widget.measurementType!);
    }

    // 주석 도구 타입 변경
    if (widget.annotationType != null &&
        oldWidget.annotationType != widget.annotationType) {
      _annotationManager.setAnnotationType(widget.annotationType!);
    }

    // 측정 색상 변경
    if (oldWidget.measurementColor != widget.measurementColor) {
      _measurementManager.setMeasurementColor(widget.measurementColor);
    }

    // 주석 색상 변경
    if (oldWidget.annotationColor != widget.annotationColor) {
      _annotationManager.setAnnotationColor(widget.annotationColor);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 이미지 처리 메서드
  Future<void> _processImage() async {
    if (widget.dicomImage.pixelData == null) return;

    try {
      // 캐싱: 동일한 밝기/대비 설정이면 재처리하지 않음
      if (_processedImage != null &&
          _lastBrightness == widget.brightness &&
          _lastContrast == widget.contrast) {
        return;
      }

      final processedImage = await _dicomService.convertPixelDataToImage(
        widget.dicomImage,
        brightness: widget.brightness,
        contrast: widget.contrast,
      );

      if (mounted) {
        setState(() {
          _processedImage = processedImage;
          _lastBrightness = widget.brightness;
          _lastContrast = widget.contrast;
        });
      }
    } catch (e) {
      print('이미지 처리 오류: $e');
    }
  }

  // 측정 시작 또는 포인트 추가
  void _handleMeasurementPoint(Offset localPosition) {
    if (!widget.isMeasurementMode) return;

    // 측정 포인트 추가
    _measurementManager.addPoint(localPosition);

    // 화면 갱신
    setState(() {});

    // 측정이 완료되면 콜백 호출
    if (_measurementManager.isCompleted &&
        widget.onMeasurementComplete != null) {
      widget.onMeasurementComplete!();
    }
  }

  // 주석 시작
  void _handleAnnotationStart(Offset localPosition) {
    if (!widget.isAnnotationMode) return;

    // 주석 시작
    _annotationManager.startAnnotation(localPosition);

    // 텍스트 주석인 경우 텍스트 입력 요청
    if (widget.annotationType == AnnotationToolType.text &&
        widget.onTextAnnotationRequested != null) {
      widget.onTextAnnotationRequested!('');
      return;
    }

    // 화면 갱신
    setState(() {});
  }

  // 주석 업데이트 (드래그 중)
  void _handleAnnotationUpdate(Offset localPosition) {
    if (!widget.isAnnotationMode ||
        _annotationManager.currentAnnotation == null)
      return;

    // 주석 업데이트
    _annotationManager.updateAnnotation(localPosition);

    // 화면 갱신
    setState(() {});
  }

  // 주석 완료
  void _handleAnnotationComplete(Offset localPosition) {
    if (!widget.isAnnotationMode ||
        _annotationManager.currentAnnotation == null)
      return;

    // 주석 완료
    _annotationManager.completeAnnotation(localPosition);

    // 화면 갱신
    setState(() {});
  }

  // 더블 탭 줌 처리
  void _handleDoubleTap(TapDownDetails details) {
    // 현재 줌 레벨 확인
    final double scale = _transformationController.value.getMaxScaleOnAxis();

    final Offset position = details.localPosition;

    if (scale >= 2.0) {
      // 줌 아웃 (원래 크기로)
      _animateResetTransformation();
    } else {
      // 줌 인 (탭한 위치로 2배 확대)
      _animateToPosition(position, 2.0);
    }
  }

  // 원래 크기로 애니메이션
  void _animateResetTransformation() {
    _homeMatrix ??= Matrix4.identity();

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: _homeMatrix,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward(from: 0);
  }

  // 특정 위치로 애니메이션
  void _animateToPosition(Offset position, double targetScale) {
    // 원본 변환 매트릭스 저장
    _homeMatrix ??= Matrix4.identity();

    // 타겟 매트릭스 계산
    final Matrix4 targetMatrix =
        Matrix4.identity()
          ..translate(
            -position.dx * (targetScale - 1),
            -position.dy * (targetScale - 1),
          )
          ..scale(targetScale);

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (widget.isMeasurementMode) {
          _handleMeasurementPoint(details.localPosition);
        } else if (widget.isAnnotationMode) {
          _handleAnnotationStart(details.localPosition);
        }
      },
      onDoubleTapDown: _handleDoubleTap,
      onPanStart: (details) {
        if (widget.isAnnotationMode) {
          _handleAnnotationStart(details.localPosition);
        }
      },
      onPanUpdate: (details) {
        if (widget.isAnnotationMode) {
          _handleAnnotationUpdate(details.localPosition);
        }
      },
      onPanEnd: (details) {
        if (widget.isAnnotationMode &&
            _annotationManager.currentAnnotation != null) {
          // 최종 포인트는 없으므로 null 전달
          _handleAnnotationComplete(
            _annotationManager.currentAnnotation!['position'],
          );
        }
      },
      child: Stack(
        children: [
          // 이미지 표시 영역
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child:
                  widget.dicomImage.pixelData != null
                      ? _processedImage != null
                          ? Image.memory(
                            _processedImage!,
                            width: widget.dicomImage.width.toDouble(),
                            height: widget.dicomImage.height.toDouble(),
                            fit: BoxFit.contain,
                            gaplessPlayback: true, // 이미지 전환 시 깜빡임 방지
                          )
                          : const Center(child: CircularProgressIndicator())
                      : Container(
                        width: widget.dicomImage.width.toDouble(),
                        height: widget.dicomImage.height.toDouble(),
                        color: Colors.black,
                        child: const Center(
                          child: Text(
                            'DICOM 이미지 데이터 없음',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
            ),
          ),

          // 측정 도구 오버레이
          if (widget.isMeasurementMode)
            CustomPaint(
              size: Size.infinite,
              painter: _measurementManager.createPainter(),
            ),

          // 주석 오버레이
          if (widget.isAnnotationMode ||
              _annotationManager.annotations.isNotEmpty)
            CustomPaint(
              size: Size.infinite,
              painter: _annotationManager.createPainter(),
            ),

          // 이미지 정보 오버레이
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '크기: ${widget.dicomImage.width} x ${widget.dicomImage.height}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '밝기: ${(widget.brightness * 100).toStringAsFixed(0)}% / 대비: ${(widget.contrast * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

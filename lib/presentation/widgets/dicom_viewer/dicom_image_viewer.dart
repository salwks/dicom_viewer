import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../data/models/dicom_file.dart';
import '../../../data/services/dicom_service.dart';
import 'painters.dart';

class DicomImageViewer extends StatefulWidget {
  final DicomImage dicomImage;
  final double brightness;
  final double contrast;
  final bool invertColors;
  final int rotationAngle;
  final bool flipHorizontal;
  final bool flipVertical;
  final bool isMeasurementMode;
  final bool isAnnotationMode;

  const DicomImageViewer({
    super.key,
    required this.dicomImage,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.invertColors = false,
    this.rotationAngle = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.isMeasurementMode = false,
    this.isAnnotationMode = false,
  });

  @override
  State<DicomImageViewer> createState() => _DicomImageViewerState();
}

class _DicomImageViewerState extends State<DicomImageViewer> {
  // 확대/축소 및 패닝을 위한 변환 매트릭스
  final TransformationController _transformationController =
      TransformationController();

  // 측정 도구 관련 변수
  List<Offset> _measurementPoints = [];

  // 주석 관련 변수
  final List<Map<String, dynamic>> _annotations = [];

  // 이미지 처리 서비스
  final DicomService _dicomService = DicomService();

  // 이미지 캐시
  Uint8List? _processedImage;
  double _lastBrightness = 0.0;
  double _lastContrast = 1.0;
  bool _lastInvertColors = false;
  int _lastRotationAngle = 0;
  bool _lastFlipHorizontal = false;
  bool _lastFlipVertical = false;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  @override
  void didUpdateWidget(DicomImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 이미지 설정이 변경되면 이미지 다시 처리
    if (oldWidget.brightness != widget.brightness ||
        oldWidget.contrast != widget.contrast ||
        oldWidget.invertColors != widget.invertColors ||
        oldWidget.rotationAngle != widget.rotationAngle ||
        oldWidget.flipHorizontal != widget.flipHorizontal ||
        oldWidget.flipVertical != widget.flipVertical ||
        oldWidget.dicomImage != widget.dicomImage) {
      _processImage();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // 이미지 처리 메서드
  Future<void> _processImage() async {
    if (widget.dicomImage.pixelData == null) return;

    try {
      // 캐싱: 동일한 설정이면 재처리하지 않음
      if (_processedImage != null &&
          _lastBrightness == widget.brightness &&
          _lastContrast == widget.contrast &&
          _lastInvertColors == widget.invertColors &&
          _lastRotationAngle == widget.rotationAngle &&
          _lastFlipHorizontal == widget.flipHorizontal &&
          _lastFlipVertical == widget.flipVertical) {
        return;
      }

      final processedImage = await _dicomService.convertPixelDataToImage(
        widget.dicomImage,
        brightness: widget.brightness,
        contrast: widget.contrast,
        invertColors: widget.invertColors,
        rotationAngle: widget.rotationAngle,
        flipHorizontal: widget.flipHorizontal,
        flipVertical: widget.flipVertical,
      );

      if (mounted) {
        setState(() {
          _processedImage = processedImage;
          _lastBrightness = widget.brightness;
          _lastContrast = widget.contrast;
          _lastInvertColors = widget.invertColors;
          _lastRotationAngle = widget.rotationAngle;
          _lastFlipHorizontal = widget.flipHorizontal;
          _lastFlipVertical = widget.flipVertical;
        });
      }
    } catch (e) {
      print('이미지 처리 오류: $e');
    }
  }

  // 측정점 추가
  void _addMeasurementPoint(Offset point) {
    if (widget.isMeasurementMode) {
      setState(() {
        if (_measurementPoints.length < 2) {
          _measurementPoints.add(point);
        } else {
          _measurementPoints = [point];
        }
      });
    }
  }

  // 주석 추가
  void _addAnnotation(Offset point) {
    if (widget.isAnnotationMode) {
      // 텍스트 컨트롤러 생성 (다이얼로그 내에서 사용)
      final textController = TextEditingController();

      // 주석 텍스트 입력 다이얼로그 표시
      showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('주석 추가'),
              content: TextField(
                controller: textController, // 컨트롤러 할당
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '주석 내용을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _annotations.add({
                        'position': point,
                        'text': value,
                        'color': Colors.green,
                      });
                    });
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    // 텍스트필드 값 가져오기
                    final text = textController.text;

                    if (text.isNotEmpty) {
                      setState(() {
                        _annotations.add({
                          'position': point,
                          'text': text,
                          'color': Colors.green,
                        });
                      });
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('추가'),
                ),
              ],
            ),
      );
    }
  }

  // 거리 계산
  double _calculateDistance() {
    if (_measurementPoints.length != 2) return 0;

    final p1 = _measurementPoints[0];
    final p2 = _measurementPoints[1];

    return (p1 - p2).distance;
  }

  // 측정값 텍스트 포맷팅
  String _formatMeasurement() {
    final pixels = _calculateDistance();

    // 픽셀 간격을 실제 물리적 거리로 변환하는 로직이 필요
    // 현재는 단순히 픽셀 값만 표시
    return '${pixels.toStringAsFixed(1)} px';
  }

  // 줌 재설정
  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);

        if (widget.isMeasurementMode) {
          _addMeasurementPoint(localPosition);
        } else if (widget.isAnnotationMode) {
          _addAnnotation(localPosition);
        }
      },
      child: Stack(
        children: [
          // 이미지 표시 영역
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.5,
            maxScale: 10.0,
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
          if (widget.isMeasurementMode || _measurementPoints.isNotEmpty)
            CustomPaint(
              size: Size.infinite,
              painter: MeasurementPainter(
                points: _measurementPoints,
                distanceText: _formatMeasurement(),
              ),
            ),

          // 주석 오버레이
          if (widget.isAnnotationMode || _annotations.isNotEmpty)
            CustomPaint(
              size: Size.infinite,
              painter: AnnotationPainter(annotations: _annotations),
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
                  if (widget.invertColors ||
                      widget.flipHorizontal ||
                      widget.flipVertical ||
                      widget.rotationAngle != 0)
                    Text(
                      '변형: ${widget.invertColors ? '반전 ' : ''}${widget.rotationAngle != 0 ? '회전(${widget.rotationAngle}°) ' : ''}${widget.flipHorizontal || widget.flipVertical ? '반사' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),

          // 줌 초기화 버튼
          Positioned(
            right: 10,
            bottom: 10,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.black.withOpacity(0.5),
              onPressed: _resetZoom,
              child: const Icon(Icons.zoom_out_map, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

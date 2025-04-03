import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../data/models/dicom_file.dart';
import '../../../data/services/dicom_service.dart';
import 'painters.dart';

class DicomImageViewer extends StatefulWidget {
  final DicomImage dicomImage;
  final double brightness;
  final double contrast;
  final bool isMeasurementMode;
  final bool isAnnotationMode;

  const DicomImageViewer({
    super.key,
    required this.dicomImage,
    this.brightness = 0.0,
    this.contrast = 1.0,
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

  @override
  void initState() {
    super.initState();
    _processImage();
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
                      _annotations.add({'position': point, 'text': value});
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
                        _annotations.add({'position': point, 'text': text});
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
              painter: MeasurementPainter(
                points: _measurementPoints,
                distance: _calculateDistance(),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

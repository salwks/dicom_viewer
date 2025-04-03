import 'package:flutter/material.dart';
import '../../../data/models/dicom_file.dart';

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

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
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
      // TODO: 주석 입력 다이얼로그 구현
      setState(() {
        _annotations.add({
          'position': point,
          'text': '주석 ${_annotations.length + 1}',
        });
      });
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
    // 현재는 더미 이미지를 표시합니다.
    // 실제 구현에서는 DICOM 픽셀 데이터를 처리하여 표시해야 합니다.
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
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  widget.contrast,
                  0,
                  0,
                  0,
                  widget.brightness * 255,
                  0,
                  widget.contrast,
                  0,
                  0,
                  widget.brightness * 255,
                  0,
                  0,
                  widget.contrast,
                  0,
                  widget.brightness * 255,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Container(
                  width: widget.dicomImage.width.toDouble(),
                  height: widget.dicomImage.height.toDouble(),
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'DICOM 이미지 표시 영역',
                      style: TextStyle(color: Colors.white),
                    ),
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
          if (widget.isAnnotationMode)
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

// 측정 도구 페인터
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

    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 점 그리기
    for (var point in points) {
      canvas.drawCircle(point, 5, paint);
    }

    // 선 그리기
    if (points.length == 2) {
      canvas.drawLine(points[0], points[1], paint);

      // 거리 표시
      final midPoint = Offset(
        (points[0].dx + points[1].dx) / 2,
        (points[0].dy + points[1].dy) / 2,
      );

      textPaint.text = TextSpan(
        text: '${distance.toStringAsFixed(1)} px',
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 14,
          backgroundColor: Colors.black54,
        ),
      );

      textPaint.layout();
      textPaint.paint(
        canvas,
        midPoint - Offset(textPaint.width / 2, textPaint.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// 주석 페인터
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

    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    for (var annotation in annotations) {
      final point = annotation['position'] as Offset;
      final text = annotation['text'] as String;

      // 주석 마커 그리기
      canvas.drawCircle(point, 5, paint);

      // 주석 텍스트 그리기
      textPaint.text = TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 14,
          backgroundColor: Colors.black54,
        ),
      );

      textPaint.layout();
      textPaint.paint(canvas, point + const Offset(10, -10));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

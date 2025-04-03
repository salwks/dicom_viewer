import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/dicom_file.dart';
import '../../data/services/dicom_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../domain/blocs/dicom/dicom_bloc.dart';
import '../../domain/blocs/dicom/dicom_event.dart';
import '../../domain/blocs/dicom/dicom_state.dart';
import '../widgets/dicom_viewer/dicom_image_viewer.dart';
import '../widgets/dicom_viewer/image_controls.dart';
import '../widgets/dicom_viewer/painters.dart';
import '../widgets/measurement_tools/measurement_tools_panel.dart';
import '../widgets/annotation_tools/annotation_tools_panel.dart';
import '../widgets/annotation_tools/annotation_manager.dart';
import 'dicom_tags_screen.dart';

class DicomViewerScreen extends StatefulWidget {
  final String filePath;

  const DicomViewerScreen({super.key, required this.filePath});

  @override
  State<DicomViewerScreen> createState() => _DicomViewerScreenState();
}

class _DicomViewerScreenState extends State<DicomViewerScreen> {
  late DicomBloc _dicomBloc;

  @override
  void initState() {
    super.initState();
    _dicomBloc = DicomBloc(
      dicomService: context.read<DicomService>(),
      storageService: context.read<LocalStorageService>(),
    );
    _dicomBloc.add(LoadDicomFile(widget.filePath));
  }

  @override
  void dispose() {
    _dicomBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dicomBloc,
      child: BlocBuilder<DicomBloc, DicomState>(
        builder: (context, state) {
          return Scaffold(
            appBar: _buildAppBar(state),
            body: _buildBody(state),
            bottomNavigationBar: _buildBottomBar(state),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(DicomState state) {
    return AppBar(
      title: Text(state.dicomFile?.summary ?? '로딩 중...'),
      actions: [
        // 태그 보기 버튼
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed:
              state.dicomFile != null
                  ? () => _navigateToDicomTags(state.dicomFile!)
                  : null,
          tooltip: 'DICOM 태그 보기',
        ),
        // 이미지 내보내기 버튼
        IconButton(
          icon: const Icon(Icons.save_alt),
          onPressed:
              state.dicomFile != null
                  ? () => _dicomBloc.add(ExportImage())
                  : null,
          tooltip: '이미지 내보내기',
        ),
      ],
    );
  }

  Widget _buildBody(DicomState state) {
    switch (state.status) {
      case DicomStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case DicomStatus.error:
        return _buildErrorView(state.errorMessage ?? '알 수 없는 오류');

      case DicomStatus.loaded:
        if (state.dicomFile == null || state.currentImage == null) {
          return const Center(child: Text('DICOM 파일을 로드할 수 없습니다'));
        }
        return _buildLoadedView(state);

      case DicomStatus.initial:
      default:
        return const Center(child: Text('DICOM 파일을 로드하는 중...'));
    }
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text('파일을 로드할 수 없습니다', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _dicomBloc.add(LoadDicomFile(widget.filePath)),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedView(DicomState state) {
    return Column(
      children: [
        // 이미지 뷰어
        Expanded(
          child: DicomImageViewer(
            dicomImage: state.currentImage!,
            brightness: state.brightness,
            contrast: state.contrast,
            isMeasurementMode: state.isMeasurementMode,
            isAnnotationMode: state.isAnnotationMode,
            measurementType: state.measurementType,
            annotationType: state.annotationType,
            measurementColor: state.measurementColor,
            annotationColor: state.annotationColor,
            onMeasurementComplete: () {
              // 측정 완료 시 처리
            },
            onTextAnnotationRequested: (text) {
              // 텍스트 주석 입력 대화상자 표시
              _showTextAnnotationDialog(text);
            },
          ),
        ),

        // 이미지 컨트롤 패널
        ImageControls(
          brightness: state.brightness,
          contrast: state.contrast,
          currentIndex: state.currentImageIndex,
          totalImages: state.dicomFile?.images.length ?? 0,
          onBrightnessChanged: (value) {
            _dicomBloc.add(UpdateBrightness(value));
          },
          onContrastChanged: (value) {
            _dicomBloc.add(UpdateContrast(value));
          },
          onIndexChanged: (index) {
            _dicomBloc.add(UpdateImageIndex(index));
          },
        ),

        // 측정 도구 패널
        if (state.isMeasurementMode)
          MeasurementToolsPanel(
            selectedTool: state.measurementType,
            onToolSelected: (tool) {
              _dicomBloc.add(SelectMeasurementTool(tool));
            },
            onClearMeasurements: () {
              _dicomBloc.add(ClearMeasurements());
            },
            onColorChanged: (color) {
              _dicomBloc.add(UpdateMeasurementColor(color));
            },
          ),

        // 주석 도구 패널
        if (state.isAnnotationMode)
          AnnotationToolsPanel(
            selectedTool: _mapToAnnotationTool(state.annotationType),
            onToolSelected: (tool) {
              _dicomBloc.add(
                SelectAnnotationTool(_mapToAnnotationToolType(tool)),
              );
            },
            onClearAnnotations: () {
              _dicomBloc.add(ClearAnnotations());
            },
            onColorChanged: (color) {
              _dicomBloc.add(UpdateAnnotationColor(color));
            },
          ),
      ],
    );
  }

  Widget _buildBottomBar(DicomState state) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 측정 도구 버튼
          IconButton(
            icon: Icon(
              Icons.straighten,
              color:
                  state.isMeasurementMode
                      ? Theme.of(context).primaryColor
                      : null,
            ),
            onPressed: () => _dicomBloc.add(ToggleMeasurementMode()),
            tooltip: '측정 도구',
          ),

          // 주석 도구 버튼
          IconButton(
            icon: Icon(
              Icons.edit,
              color:
                  state.isAnnotationMode
                      ? Theme.of(context).primaryColor
                      : null,
            ),
            onPressed: () => _dicomBloc.add(ToggleAnnotationMode()),
            tooltip: '주석 도구',
          ),

          // 이미지 회전 버튼
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_ccw),
            onPressed: () => _dicomBloc.add(const RotateImage(90)),
            tooltip: '이미지 회전',
          ),

          // 이미지 좌우 반전 버튼
          IconButton(
            icon: const Icon(Icons.flip),
            onPressed: () => _dicomBloc.add(const FlipImage(horizontal: true)),
            tooltip: '좌우 반전',
          ),

          // 이미지 상하 반전 버튼
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _dicomBloc.add(const FlipImage(horizontal: false)),
            tooltip: '상하 반전',
          ),

          // 설정 저장 버튼
          IconButton(
            icon: const Icon(Icons.save),
            onPressed:
                () => _dicomBloc.add(
                  SaveDicomSettings(
                    brightness: state.brightness,
                    contrast: state.contrast,
                  ),
                ),
            tooltip: '설정 저장',
          ),
        ],
      ),
    );
  }

  // 텍스트 주석 입력 대화상자
  void _showTextAnnotationDialog(String initialText) {
    final textController = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('주석 텍스트 입력'),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: '주석 내용을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // 주석 취소
                  Navigator.of(context).pop();
                  _dicomBloc.add(CancelAnnotation());
                },
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  // 주석 완료
                  Navigator.of(context).pop();
                  if (textController.text.isNotEmpty) {
                    _dicomBloc.add(CompleteAnnotation(textController.text));
                  } else {
                    _dicomBloc.add(CancelAnnotation());
                  }
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  // DICOM 태그 화면으로 이동
  void _navigateToDicomTags(DicomFile dicomFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DicomTagsScreen(dicomFile: dicomFile),
      ),
    );
  }

  // AnnotationToolType을 AnnotationTool로 변환
  AnnotationTool _mapToAnnotationTool(AnnotationToolType type) {
    switch (type) {
      case AnnotationToolType.text:
        return AnnotationTool.text;
      case AnnotationToolType.arrow:
        return AnnotationTool.arrow;
      case AnnotationToolType.freehand:
        return AnnotationTool.freehand;
      case AnnotationToolType.marker:
        return AnnotationTool.marker;
      case AnnotationToolType.rectangle:
        return AnnotationTool.rectangle;
    }
  }

  // AnnotationTool을 AnnotationToolType으로 변환
  AnnotationToolType _mapToAnnotationToolType(AnnotationTool tool) {
    switch (tool) {
      case AnnotationTool.text:
        return AnnotationToolType.text;
      case AnnotationTool.arrow:
        return AnnotationToolType.arrow;
      case AnnotationTool.freehand:
        return AnnotationToolType.freehand;
      case AnnotationTool.marker:
        return AnnotationToolType.marker;
      case AnnotationTool.rectangle:
        return AnnotationToolType.rectangle;
    }
  }
}

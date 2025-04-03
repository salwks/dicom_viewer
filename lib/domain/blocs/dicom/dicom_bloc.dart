import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/dicom_service.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../presentation/widgets/dicom_viewer/painters.dart';
import '../../../presentation/widgets/annotation_tools/annotation_manager.dart';
import 'dicom_event.dart';
import 'dicom_state.dart';

class DicomBloc extends Bloc<DicomEvent, DicomState> {
  final DicomService _dicomService;
  final LocalStorageService _storageService;

  DicomBloc({
    required DicomService dicomService,
    required LocalStorageService storageService,
  }) : _dicomService = dicomService,
       _storageService = storageService,
       super(const DicomState()) {
    // 이벤트 핸들러 등록
    on<LoadDicomFile>(_onLoadDicomFile);
    on<UpdateBrightness>(_onUpdateBrightness);
    on<UpdateContrast>(_onUpdateContrast);
    on<UpdateImageIndex>(_onUpdateImageIndex);
    on<SaveDicomSettings>(_onSaveDicomSettings);

    // 측정 도구 이벤트
    on<ToggleMeasurementMode>(_onToggleMeasurementMode);
    on<SelectMeasurementTool>(_onSelectMeasurementTool);
    on<UpdateMeasurementColor>(_onUpdateMeasurementColor);
    on<AddMeasurementPoint>(_onAddMeasurementPoint);
    on<ClearMeasurements>(_onClearMeasurements);

    // 주석 도구 이벤트
    on<ToggleAnnotationMode>(_onToggleAnnotationMode);
    on<SelectAnnotationTool>(_onSelectAnnotationTool);
    on<UpdateAnnotationColor>(_onUpdateAnnotationColor);
    on<AddAnnotation>(_onAddAnnotation);
    on<CompleteAnnotation>(_onCompleteAnnotation);
    on<CancelAnnotation>(_onCancelAnnotation);
    on<ClearAnnotations>(_onClearAnnotations);

    // 이미지 변환 이벤트
    on<RotateImage>(_onRotateImage);
    on<FlipImage>(_onFlipImage);

    // 저장 및 내보내기 이벤트
    on<SaveMeasurements>(_onSaveMeasurements);
    on<SaveAnnotations>(_onSaveAnnotations);
    on<ExportImage>(_onExportImage);
  }

  Future<void> _onLoadDicomFile(
    LoadDicomFile event,
    Emitter<DicomState> emit,
  ) async {
    try {
      emit(state.copyWith(status: DicomStatus.loading));

      // 설정 로드
      final settings = await _storageService.loadSettings();
      final defaultBrightness = settings['defaultBrightness'] as double;
      final defaultContrast = settings['defaultContrast'] as double;

      // DICOM 파일 로드
      final dicomFile = await _dicomService.loadDicomFile(event.filePath);

      // 최근 파일 목록에 추가
      await _storageService.saveRecentFile(dicomFile);

      emit(
        state.copyWith(
          status: DicomStatus.loaded,
          dicomFile: dicomFile,
          brightness: defaultBrightness,
          contrast: defaultContrast,
          currentImageIndex: 0,
          errorMessage: null,
          // 측정 및 주석 초기화
          measurements: const [],
          annotations: const [],
          rotation: 0,
          flipHorizontal: false,
          flipVertical: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DicomStatus.error,
          errorMessage: '파일 로드 중 오류 발생: $e',
        ),
      );
    }
  }

  void _onUpdateBrightness(UpdateBrightness event, Emitter<DicomState> emit) {
    emit(state.copyWith(brightness: event.brightness));
  }

  void _onUpdateContrast(UpdateContrast event, Emitter<DicomState> emit) {
    emit(state.copyWith(contrast: event.contrast));
  }

  void _onUpdateImageIndex(UpdateImageIndex event, Emitter<DicomState> emit) {
    if (state.dicomFile != null &&
        event.index >= 0 &&
        event.index < state.dicomFile!.images.length) {
      emit(state.copyWith(currentImageIndex: event.index));
    }
  }

  Future<void> _onSaveDicomSettings(
    SaveDicomSettings event,
    Emitter<DicomState> emit,
  ) async {
    try {
      await _storageService.saveSettings(
        defaultBrightness: event.brightness,
        defaultContrast: event.contrast,
      );
    } catch (e) {
      print('설정 저장 중 오류: $e');
    }
  }

  void _onToggleMeasurementMode(
    ToggleMeasurementMode event,
    Emitter<DicomState> emit,
  ) {
    final newMeasurementMode = !state.isMeasurementMode;

    emit(
      state.copyWith(
        isMeasurementMode: newMeasurementMode,
        isAnnotationMode: newMeasurementMode ? false : state.isAnnotationMode,
      ),
    );
  }

  void _onSelectMeasurementTool(
    SelectMeasurementTool event,
    Emitter<DicomState> emit,
  ) {
    emit(
      state.copyWith(
        measurementType: event.type,
        isMeasurementMode: true,
        isAnnotationMode: false,
      ),
    );
  }

  void _onUpdateMeasurementColor(
    UpdateMeasurementColor event,
    Emitter<DicomState> emit,
  ) {
    emit(state.copyWith(measurementColor: event.color));
  }

  void _onAddMeasurementPoint(
    AddMeasurementPoint event,
    Emitter<DicomState> emit,
  ) {
    // 현재 구현에서는 측정 포인트가 별도 객체로 관리됨
    // 여기서는 측정이 완료된 결과만 저장
  }

  void _onClearMeasurements(ClearMeasurements event, Emitter<DicomState> emit) {
    emit(state.copyWith(measurements: const []));
  }

  void _onToggleAnnotationMode(
    ToggleAnnotationMode event,
    Emitter<DicomState> emit,
  ) {
    final newAnnotationMode = !state.isAnnotationMode;

    emit(
      state.copyWith(
        isAnnotationMode: newAnnotationMode,
        isMeasurementMode: newAnnotationMode ? false : state.isMeasurementMode,
      ),
    );
  }

  void _onSelectAnnotationTool(
    SelectAnnotationTool event,
    Emitter<DicomState> emit,
  ) {
    emit(
      state.copyWith(
        annotationType: event.type,
        isAnnotationMode: true,
        isMeasurementMode: false,
      ),
    );
  }

  void _onUpdateAnnotationColor(
    UpdateAnnotationColor event,
    Emitter<DicomState> emit,
  ) {
    emit(state.copyWith(annotationColor: event.color));
  }

  void _onAddAnnotation(AddAnnotation event, Emitter<DicomState> emit) {
    final currentAnnotations = List<Map<String, dynamic>>.from(
      state.annotations,
    );

    // 주석 타입에 따라 다른 형태로 추가
    Map<String, dynamic> newAnnotation = {
      'position': Offset(event.x, event.y),
      'text': event.text,
      'type': event.type ?? 'text',
      'color': state.annotationColor,
    };

    currentAnnotations.add(newAnnotation);

    emit(state.copyWith(annotations: currentAnnotations));
  }

  void _onCompleteAnnotation(
    CompleteAnnotation event,
    Emitter<DicomState> emit,
  ) {
    // 주석 완료 처리는 _onAddAnnotation에서 이미 처리됨
  }

  void _onCancelAnnotation(CancelAnnotation event, Emitter<DicomState> emit) {
    // 현재 주석 작업 취소
  }

  void _onClearAnnotations(ClearAnnotations event, Emitter<DicomState> emit) {
    emit(state.copyWith(annotations: const []));
  }

  void _onRotateImage(RotateImage event, Emitter<DicomState> emit) {
    // 현재 회전 각도
    final currentRotation = state.rotation;

    // 새 회전 각도 (0, 90, 180, 270 중 하나)
    final newRotation = (currentRotation + event.degrees) % 360;

    emit(state.copyWith(rotation: newRotation));
  }

  void _onFlipImage(FlipImage event, Emitter<DicomState> emit) {
    if (event.horizontal) {
      emit(state.copyWith(flipHorizontal: !state.flipHorizontal));
    } else {
      emit(state.copyWith(flipVertical: !state.flipVertical));
    }
  }

  Future<void> _onSaveMeasurements(
    SaveMeasurements event,
    Emitter<DicomState> emit,
  ) async {
    // TODO: 측정 결과 저장 로직 구현
    try {
      // 측정 데이터를 영구 저장소에 저장하는 로직 추가
    } catch (e) {
      print('측정 저장 중 오류: $e');
    }
  }

  Future<void> _onSaveAnnotations(
    SaveAnnotations event,
    Emitter<DicomState> emit,
  ) async {
    // TODO: 주석 저장 로직 구현
    try {
      // 주석 데이터를 영구 저장소에 저장하는 로직 추가
    } catch (e) {
      print('주석 저장 중 오류: $e');
    }
  }

  Future<void> _onExportImage(
    ExportImage event,
    Emitter<DicomState> emit,
  ) async {
    // TODO: 현재 이미지 내보내기 로직 구현
    try {
      // 현재 이미지를 파일로 내보내는 로직 추가
    } catch (e) {
      print('이미지 내보내기 중 오류: $e');
    }
  }
}

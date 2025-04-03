import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/dicom_service.dart';
import '../../../data/services/local_storage_service.dart';
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
    on<ToggleMeasurementMode>(_onToggleMeasurementMode);
    on<ToggleAnnotationMode>(_onToggleAnnotationMode);
    on<AddMeasurementPoint>(_onAddMeasurementPoint);
    on<ClearMeasurements>(_onClearMeasurements);
    on<AddAnnotation>(_onAddAnnotation);
    on<ClearAnnotations>(_onClearAnnotations);
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

  void _onAddMeasurementPoint(
    AddMeasurementPoint event,
    Emitter<DicomState> emit,
  ) {
    final currentPoints = List<Map<String, double>>.from(
      state.measurementPoints,
    );

    if (currentPoints.length < 2) {
      currentPoints.add({'x': event.x, 'y': event.y});
    } else {
      currentPoints.clear();
      currentPoints.add({'x': event.x, 'y': event.y});
    }

    emit(state.copyWith(measurementPoints: currentPoints));
  }

  void _onClearMeasurements(ClearMeasurements event, Emitter<DicomState> emit) {
    emit(state.copyWith(measurementPoints: []));
  }

  void _onAddAnnotation(AddAnnotation event, Emitter<DicomState> emit) {
    final currentAnnotations = List<Map<String, dynamic>>.from(
      state.annotations,
    );

    currentAnnotations.add({'x': event.x, 'y': event.y, 'text': event.text});

    emit(state.copyWith(annotations: currentAnnotations));
  }

  void _onClearAnnotations(ClearAnnotations event, Emitter<DicomState> emit) {
    emit(state.copyWith(annotations: []));
  }
}

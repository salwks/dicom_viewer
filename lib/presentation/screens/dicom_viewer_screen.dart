import 'package:flutter/material.dart';
import '../../data/models/dicom_file.dart';
import '../widgets/dicom_viewer/dicom_image_viewer.dart';
import '../widgets/dicom_viewer/image_controls.dart';
import '../widgets/measurement_tools/measurement_tools_panel.dart';
import '../widgets/annotation_tools/annotation_tools_panel.dart';
import 'dicom_tags_screen.dart';

class DicomViewerScreen extends StatefulWidget {
  final String filePath;

  const DicomViewerScreen({super.key, required this.filePath});

  @override
  State<DicomViewerScreen> createState() => _DicomViewerScreenState();
}

class _DicomViewerScreenState extends State<DicomViewerScreen>
    with SingleTickerProviderStateMixin {
  // 상태 변수
  double _brightness = 0.0;
  double _contrast = 1.0;
  DicomFile? _dicomFile;
  int _currentImageIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // 도구 상태
  bool _isMeasurementMode = false;
  bool _isAnnotationMode = false;

  // 탭 컨트롤러
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDicomFile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // DICOM 파일 로드
  Future<void> _loadDicomFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // TODO: 실제 DICOM 파싱 로직 구현
      // 아래는 더미 데이터로 구현
      await Future.delayed(const Duration(seconds: 2)); // 로딩 시뮬레이션

      // 여기에 실제 DICOM 파싱 로직이 들어갈 예정
      // 현재는 샘플 데이터로 대체
      final dummyImages = List.generate(
        3,
        (index) => DicomImage(
          index: index,
          pixelData: null, // 실제 구현에서는 픽셀 데이터 필요
          width: 512,
          height: 512,
          bitsAllocated: 16,
          bitsStored: 12,
          highBit: 11,
          samplesPerPixel: 1,
          isColor: false,
          photometricInterpretation: 'MONOCHROME2',
          windowCenter: 40,
          windowWidth: 400,
        ),
      );

      final dummyTags = {
        '00100010': DicomTag(
          name: 'PatientName',
          group: '0010',
          element: '0010',
          vr: 'PN',
          value: '홍길동',
        ),
        '00100020': DicomTag(
          name: 'PatientID',
          group: '0010',
          element: '0020',
          vr: 'LO',
          value: '12345678',
        ),
        // 추가 태그...
      };

      _dicomFile = DicomFile(
        filePath: widget.filePath,
        patientName: '홍길동',
        patientId: '12345678',
        studyDate: '20230101',
        studyDescription: 'CT BRAIN',
        seriesDescription: 'AXIAL',
        modality: 'CT',
        images: dummyImages,
        tags: dummyTags,
        dateAdded: DateTime.now(),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // 밝기 조정
  void _updateBrightness(double value) {
    setState(() => _brightness = value);
  }

  // 대비 조정
  void _updateContrast(double value) {
    setState(() => _contrast = value);
  }

  // 이미지 인덱스 변경
  void _updateImageIndex(int index) {
    if (_dicomFile != null && index >= 0 && index < _dicomFile!.images.length) {
      setState(() => _currentImageIndex = index);
    }
  }

  // 측정 모드 토글
  void _toggleMeasurementMode() {
    setState(() {
      _isMeasurementMode = !_isMeasurementMode;
      if (_isMeasurementMode) {
        _isAnnotationMode = false;
      }
    });
  }

  // 주석 모드 토글
  void _toggleAnnotationMode() {
    setState(() {
      _isAnnotationMode = !_isAnnotationMode;
      if (_isAnnotationMode) {
        _isMeasurementMode = false;
      }
    });
  }

  // DICOM 태그 화면으로 이동
  void _navigateToDicomTags() {
    if (_dicomFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DicomTagsScreen(dicomFile: _dicomFile!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dicomFile?.summary ?? '로딩 중...'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _dicomFile != null ? _navigateToDicomTags : null,
            tooltip: 'DICOM 태그 보기',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomControls(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              '파일을 로드할 수 없습니다',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_dicomFile == null) {
      return const Center(child: Text('파일을 로드할 수 없습니다'));
    }

    return Column(
      children: [
        // 이미지 뷰어
        Expanded(
          child: DicomImageViewer(
            dicomImage: _dicomFile!.images[_currentImageIndex],
            brightness: _brightness,
            contrast: _contrast,
            isMeasurementMode: _isMeasurementMode,
            isAnnotationMode: _isAnnotationMode,
          ),
        ),

        // 이미지 컨트롤 패널
        ImageControls(
          brightness: _brightness,
          contrast: _contrast,
          currentIndex: _currentImageIndex,
          totalImages: _dicomFile!.images.length,
          onBrightnessChanged: _updateBrightness,
          onContrastChanged: _updateContrast,
          onIndexChanged: _updateImageIndex,
        ),

        // 도구 패널 (측정 또는 주석)
        if (_isMeasurementMode)
          MeasurementToolsPanel(
            onToolSelected: (tool) {
              // TODO: 측정 도구 선택 처리
            },
          ),

        if (_isAnnotationMode)
          AnnotationToolsPanel(
            onToolSelected: (tool) {
              // TODO: 주석 도구 선택 처리
            },
          ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.straighten,
              color: _isMeasurementMode ? Theme.of(context).primaryColor : null,
            ),
            onPressed: _toggleMeasurementMode,
            tooltip: '측정 도구',
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: _isAnnotationMode ? Theme.of(context).primaryColor : null,
            ),
            onPressed: _toggleAnnotationMode,
            tooltip: '주석 도구',
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_ccw),
            onPressed: () {
              // TODO: 이미지 회전 처리
            },
            tooltip: '이미지 회전',
          ),
          IconButton(
            icon: const Icon(Icons.flip),
            onPressed: () {
              // TODO: 이미지 반전 처리
            },
            tooltip: '이미지 반전',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: 현재 상태 저장 처리
            },
            tooltip: '저장',
          ),
        ],
      ),
    );
  }
}

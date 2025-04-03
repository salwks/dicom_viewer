import 'package:flutter/material.dart';
import '../../data/models/dicom_file.dart';
import '../../data/services/dicom_service.dart';
import '../../data/services/local_storage_service.dart';
import '../widgets/dicom_viewer/dicom_image_viewer.dart';
import '../widgets/dicom_viewer/image_controls.dart';
import '../widgets/measurement_tools/measurement_tools_panel.dart';
import '../widgets/annotation_tools/annotation_tools_panel.dart';
import 'dicom_tags_screen.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // 서비스 인스턴스
  final DicomService _dicomService = DicomService();
  final LocalStorageService _localStorageService = LocalStorageService();

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

      // 설정 로드
      final settings = await _localStorageService.loadSettings();
      final defaultBrightness = settings['defaultBrightness'] as double;
      final defaultContrast = settings['defaultContrast'] as double;

      // DICOM 파일 파싱 (더미 구현 사용)
      final dicomFile = await _dicomService.loadDicomFile(widget.filePath);

      // 최근 파일 목록에 추가
      await _localStorageService.saveRecentFile(dicomFile);

      if (mounted) {
        setState(() {
          _dicomFile = dicomFile;
          _isLoading = false;
          _brightness = defaultBrightness;
          _contrast = defaultContrast;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
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

  // 이미지 회전 처리
  void _rotateImage() {
    // TODO: 추후 구현
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이미지 회전 기능은 아직 구현되지 않았습니다')));
  }

  // 이미지 반전 처리
  void _flipImage() {
    // TODO: 추후 구현
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이미지 반전 기능은 아직 구현되지 않았습니다')));
  }

  // 현재 상태 저장
  void _saveCurrentState() {
    // 기본 밝기/대비 설정 저장
    _localStorageService
        .saveSettings(
          defaultBrightness: _brightness,
          defaultContrast: _contrast,
        )
        .then((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('현재 설정이 저장되었습니다')));
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadDicomFile,
              child: const Text('다시 시도'),
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
              // 테스트용 메시지 표시
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${tool.name} 측정 도구가 선택되었습니다')),
              );
            },
          ),

        if (_isAnnotationMode)
          AnnotationToolsPanel(
            onToolSelected: (tool) {
              // 테스트용 메시지 표시
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${tool.name} 주석 도구가 선택되었습니다')),
              );
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
            onPressed: _rotateImage,
            tooltip: '이미지 회전',
          ),
          IconButton(
            icon: const Icon(Icons.flip),
            onPressed: _flipImage,
            tooltip: '이미지 반전',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCurrentState,
            tooltip: '설정 저장',
          ),
        ],
      ),
    );
  }
}

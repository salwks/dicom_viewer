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
  bool _invertColors = false;
  int _rotationAngle = 0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;
  DicomFile? _dicomFile;
  int _currentImageIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // 도구 상태
  bool _isMeasurementMode = false;
  bool _isAnnotationMode = false;
  MeasurementTool _selectedMeasurementTool = MeasurementTool.line;
  AnnotationTool _selectedAnnotationTool = AnnotationTool.text;

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

  // 색상 반전 토글
  void _toggleInvertColors() {
    setState(() => _invertColors = !_invertColors);
  }

  // 이미지 회전
  void _rotateImage(int angle) {
    setState(() {
      _rotationAngle = (_rotationAngle + angle) % 360;
    });
  }

  // 수평 반전 토글
  void _toggleFlipHorizontal() {
    setState(() => _flipHorizontal = !_flipHorizontal);
  }

  // 수직 반전 토글
  void _toggleFlipVertical() {
    setState(() => _flipVertical = !_flipVertical);
  }

  // 이미지 설정 초기화
  void _resetImageSettings() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _invertColors = false;
      _rotationAngle = 0;
      _flipHorizontal = false;
      _flipVertical = false;
    });
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

  // 측정 도구 선택 처리
  void _handleMeasurementToolSelected(MeasurementTool tool) {
    setState(() {
      _selectedMeasurementTool = tool;
    });
    // 실제 구현에서는 선택된 도구를 사용하여 측정 기능 활성화
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${tool.name} 측정 도구가 선택되었습니다')));
  }

  // 주석 도구 선택 처리
  void _handleAnnotationToolSelected(AnnotationTool tool) {
    setState(() {
      _selectedAnnotationTool = tool;
    });
    // 실제 구현에서는 선택된 도구를 사용하여 주석 기능 활성화
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${tool.name} 주석 도구가 선택되었습니다')));
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

  // 이미지 저장
  Future<void> _saveImage() async {
    // 저장 권한 확인
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지를 저장하려면 저장소 권한이 필요합니다')));
      return;
    }

    // 저장 로직 구현
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이미지 저장 기능은 준비 중입니다')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dicomFile?.summary ?? '로딩 중...'),
        actions: [
          // 이미지 저장 버튼
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _dicomFile != null ? _saveImage : null,
            tooltip: '이미지 저장',
          ),
          // DICOM 태그 보기 버튼
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _dicomFile != null ? _navigateToDicomTags : null,
            tooltip: 'DICOM 태그 보기',
          ),
          // 더보기 메뉴
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _resetImageSettings();
                  break;
                case 'save_settings':
                  _saveCurrentState();
                  break;
                case 'export':
                  // TODO: DICOM 내보내기 구현
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'reset',
                    child: Text('이미지 설정 초기화'),
                  ),
                  const PopupMenuItem(
                    value: 'save_settings',
                    child: Text('현재 설정 저장'),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Text('DICOM 내보내기'),
                  ),
                ],
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
            invertColors: _invertColors,
            rotationAngle: _rotationAngle,
            flipHorizontal: _flipHorizontal,
            flipVertical: _flipVertical,
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
            selectedTool: _selectedMeasurementTool,
            onToolSelected: _handleMeasurementToolSelected,
          ),

        if (_isAnnotationMode)
          AnnotationToolsPanel(
            selectedTool: _selectedAnnotationTool,
            onToolSelected: _handleAnnotationToolSelected,
          ),
      ],
    );
  }

  Widget _buildBottomControls() {
    // 이미지 처리 옵션을 위한 BottomSheet 표시
    void showImageProcessingOptions() {
      showModalBottomSheet(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder:
                  (context, setSheetState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBar(
                        title: const Text('이미지 설정'),
                        automaticallyImplyLeading: false,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      ListTile(
                        leading: const Icon(Icons.invert_colors),
                        title: const Text('색상 반전'),
                        trailing: Switch(
                          value: _invertColors,
                          onChanged: (value) {
                            setSheetState(() {
                              setState(() => _invertColors = value);
                            });
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.rotate_right),
                        title: const Text('이미지 회전'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.rotate_left),
                              onPressed: () {
                                setSheetState(() {
                                  setState(
                                    () =>
                                        _rotationAngle =
                                            (_rotationAngle - 90) % 360,
                                  );
                                });
                              },
                            ),
                            Text('$_rotationAngle°'),
                            IconButton(
                              icon: const Icon(Icons.rotate_right),
                              onPressed: () {
                                setSheetState(() {
                                  setState(
                                    () =>
                                        _rotationAngle =
                                            (_rotationAngle + 90) % 360,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.flip),
                        title: const Text('수평 반전'),
                        trailing: Switch(
                          value: _flipHorizontal,
                          onChanged: (value) {
                            setSheetState(() {
                              setState(() => _flipHorizontal = value);
                            });
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.flip),
                        title: const Text('수직 반전'),
                        trailing: Switch(
                          value: _flipVertical,
                          onChanged: (value) {
                            setSheetState(() {
                              setState(() => _flipVertical = value);
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _resetImageSettings();
                            Navigator.pop(context);
                          },
                          child: const Text('설정 초기화'),
                        ),
                      ),
                    ],
                  ),
            ),
      );
    }

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
            icon: const Icon(Icons.tune),
            onPressed: showImageProcessingOptions,
            tooltip: '이미지 설정',
          ),
          IconButton(
            icon: const Icon(Icons.invert_colors),
            onPressed: _toggleInvertColors,
            tooltip: '색상 반전',
            color: _invertColors ? Theme.of(context).primaryColor : null,
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

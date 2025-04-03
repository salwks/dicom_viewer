import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dicom_viewer_screen.dart';
import 'recent_files_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // DICOM 파일 선택
  Future<void> _pickDicomFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dcm', 'dicom'],
      );

      if (result != null && result.files.isNotEmpty) {
        String filePath = result.files.first.path!;
        // 여기서는 실제 DICOM 파싱 없이 뷰어 화면으로 이동
        // 실제 구현에서는 DICOM 파싱 로직 추가 필요
        _navigateToDicomViewer(context, filePath);
      }
    } catch (e) {
      _showErrorDialog(context, '파일 선택 오류', e.toString());
    }
  }

  // DICOM 뷰어 화면으로 이동
  void _navigateToDicomViewer(BuildContext context, String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DicomViewerScreen(filePath: filePath),
      ),
    );
  }

  // 최근 파일 화면으로 이동
  void _navigateToRecentFiles(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecentFilesScreen()),
    );
  }

  // 설정 화면으로 이동
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  // 에러 다이얼로그 표시
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DICOM 뷰어'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 로고 또는 이미지
              const Icon(
                Icons.medical_information,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                '모바일 DICOM 뷰어',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '의료 영상을 어디서나 확인하고 분석하세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () => _pickDicomFile(context),
                icon: const Icon(Icons.file_open),
                label: const Text('DICOM 파일 열기'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () => _navigateToRecentFiles(context),
                icon: const Icon(Icons.history),
                label: const Text('최근 파일'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

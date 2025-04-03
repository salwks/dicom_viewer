import 'package:flutter/material.dart';
import '../../data/models/dicom_file.dart';
import 'dicom_viewer_screen.dart';

class RecentFilesScreen extends StatefulWidget {
  const RecentFilesScreen({super.key});

  @override
  State<RecentFilesScreen> createState() => _RecentFilesScreenState();
}

class _RecentFilesScreenState extends State<RecentFilesScreen> {
  // 최근 파일 목록
  List<DicomFile> _recentFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  // 최근 파일 로드
  Future<void> _loadRecentFiles() async {
    // TODO: 실제 저장된 최근 파일 로드 로직 구현
    // 현재는 더미 데이터로 대체

    await Future.delayed(const Duration(seconds: 1)); // 로딩 시뮬레이션

    setState(() {
      _recentFiles = List.generate(
        5,
        (index) => DicomFile(
          filePath: '/path/to/file_$index.dcm',
          patientName: '홍길동 ${index + 1}',
          patientId: '1000${index + 1}',
          studyDate: '20230${index + 1}01',
          studyDescription: 'CT BRAIN',
          seriesDescription: 'AXIAL',
          modality: index % 2 == 0 ? 'CT' : 'MR',
          images: [],
          tags: {},
          dateAdded: DateTime.now().subtract(Duration(days: index)),
        ),
      );
      _isLoading = false;
    });
  }

  // 파일 열기
  void _openFile(DicomFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DicomViewerScreen(filePath: file.filePath),
      ),
    );
  }

  // 파일 삭제
  void _deleteFile(DicomFile file) {
    // TODO: 실제 저장소에서 삭제 로직 구현
    setState(() {
      _recentFiles.remove(file);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${file.patientName}의 파일이 삭제되었습니다'),
        action: SnackBarAction(
          label: '실행 취소',
          onPressed: () {
            // TODO: 실제 삭제 취소 로직 구현
            setState(() {
              _recentFiles.add(file);
              _recentFiles.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('최근 파일')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recentFiles.isEmpty
              ? _buildEmptyState()
              : _buildFileList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '최근에 열어본 파일이 없습니다',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('DICOM 파일을 열면 이곳에 표시됩니다', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      itemCount: _recentFiles.length,
      itemBuilder: (context, index) {
        final file = _recentFiles[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  file.modality == 'CT' ? Colors.blue : Colors.green,
              child: Text(
                file.modality,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(file.patientName),
            subtitle: Text(
              '${file.patientId} - ${file.studyDescription} - ${file.studyDate}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteFile(file),
            ),
            onTap: () => _openFile(file),
          ),
        );
      },
    );
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dicom_file.dart';

class LocalStorageService {
  static const String _recentFilesKey = 'recent_files';
  static const int _maxRecentFiles = 10;

  /// 최근 열어본 DICOM 파일 정보를 저장합니다.
  Future<void> saveRecentFile(DicomFile file) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 기존 최근 파일 목록 로드
      List<String> recentFiles = prefs.getStringList(_recentFilesKey) ?? [];

      // 파일 메타 정보만 JSON으로 저장 (이미지 데이터는 제외)
      final fileJson = jsonEncode({
        'filePath': file.filePath,
        'patientName': file.patientName,
        'patientId': file.patientId,
        'studyDate': file.studyDate,
        'studyDescription': file.studyDescription,
        'seriesDescription': file.seriesDescription,
        'modality': file.modality,
        'dateAdded': DateTime.now().toIso8601String(),
      });

      // 이미 목록에 있는 동일한 경로의 파일 제거
      recentFiles.removeWhere((item) {
        final decoded = jsonDecode(item);
        return decoded['filePath'] == file.filePath;
      });

      // 새 파일을 목록 맨 앞에 추가
      recentFiles.insert(0, fileJson);

      // 최대 개수 제한
      if (recentFiles.length > _maxRecentFiles) {
        recentFiles = recentFiles.sublist(0, _maxRecentFiles);
      }

      // 저장
      await prefs.setStringList(_recentFilesKey, recentFiles);
    } catch (e) {
      print('최근 파일 저장 오류: $e');
    }
  }

  /// 최근 열어본 DICOM 파일 목록을 로드합니다.
  Future<List<DicomFile>> loadRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentFiles = prefs.getStringList(_recentFilesKey) ?? [];

      return recentFiles.map((fileJson) {
        final Map<String, dynamic> data = jsonDecode(fileJson);

        return DicomFile(
          filePath: data['filePath'],
          patientName: data['patientName'],
          patientId: data['patientId'],
          studyDate: data['studyDate'],
          studyDescription: data['studyDescription'] ?? '',
          seriesDescription: data['seriesDescription'] ?? '',
          modality: data['modality'],
          images: [], // 이미지는 실제 파일 열 때 로드
          tags: {}, // 태그도 실제 파일 열 때 로드
          dateAdded: DateTime.parse(data['dateAdded']),
        );
      }).toList();
    } catch (e) {
      print('최근 파일 로드 오류: $e');
      return [];
    }
  }

  /// 특정 파일을 최근 목록에서 제거합니다.
  Future<void> removeRecentFile(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 기존 목록 로드
      List<String> recentFiles = prefs.getStringList(_recentFilesKey) ?? [];

      // 해당 파일 경로를 가진 항목 제거
      recentFiles.removeWhere((item) {
        final decoded = jsonDecode(item);
        return decoded['filePath'] == filePath;
      });

      // 저장
      await prefs.setStringList(_recentFilesKey, recentFiles);
    } catch (e) {
      print('최근 파일 삭제 오류: $e');
    }
  }

  /// 모든 최근 파일 기록을 삭제합니다.
  Future<void> clearRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentFilesKey);
    } catch (e) {
      print('최근 파일 목록 초기화 오류: $e');
    }
  }

  /// 앱 설정을 저장합니다.
  Future<void> saveSettings({
    bool? isDarkMode,
    bool? highQualityRendering,
    bool? saveAnnotations,
    double? defaultBrightness,
    double? defaultContrast,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (isDarkMode != null) {
        await prefs.setBool('isDarkMode', isDarkMode);
      }

      if (highQualityRendering != null) {
        await prefs.setBool('highQualityRendering', highQualityRendering);
      }

      if (saveAnnotations != null) {
        await prefs.setBool('saveAnnotations', saveAnnotations);
      }

      if (defaultBrightness != null) {
        await prefs.setDouble('defaultBrightness', defaultBrightness);
      }

      if (defaultContrast != null) {
        await prefs.setDouble('defaultContrast', defaultContrast);
      }
    } catch (e) {
      print('설정 저장 오류: $e');
    }
  }

  /// 앱 설정을 로드합니다.
  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'isDarkMode': prefs.getBool('isDarkMode') ?? false,
        'highQualityRendering': prefs.getBool('highQualityRendering') ?? true,
        'saveAnnotations': prefs.getBool('saveAnnotations') ?? true,
        'defaultBrightness': prefs.getDouble('defaultBrightness') ?? 0.0,
        'defaultContrast': prefs.getDouble('defaultContrast') ?? 1.0,
      };
    } catch (e) {
      print('설정 로드 오류: $e');
      // 기본값 반환
      return {
        'isDarkMode': false,
        'highQualityRendering': true,
        'saveAnnotations': true,
        'defaultBrightness': 0.0,
        'defaultContrast': 1.0,
      };
    }
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 설정 값
  bool _isDarkMode = false;
  bool _highQualityRendering = true;
  bool _saveAnnotations = true;
  double _defaultBrightness = 0.0;
  double _defaultContrast = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 설정 로드
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _highQualityRendering = prefs.getBool('highQualityRendering') ?? true;
      _saveAnnotations = prefs.getBool('saveAnnotations') ?? true;
      _defaultBrightness = prefs.getDouble('defaultBrightness') ?? 0.0;
      _defaultContrast = prefs.getDouble('defaultContrast') ?? 1.0;
    });
  }

  // 설정 저장
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('highQualityRendering', _highQualityRendering);
    await prefs.setBool('saveAnnotations', _saveAnnotations);
    await prefs.setDouble('defaultBrightness', _defaultBrightness);
    await prefs.setDouble('defaultContrast', _defaultContrast);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('설정이 저장되었습니다'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          _buildSectionHeader('앱 설정'),
          SwitchListTile(
            title: const Text('다크 모드'),
            subtitle: const Text('어두운 테마 사용'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
            },
          ),
          _buildDivider(),

          _buildSectionHeader('이미지 설정'),
          SwitchListTile(
            title: const Text('고품질 렌더링'),
            subtitle: const Text('더 선명한 이미지(성능 저하 가능)'),
            value: _highQualityRendering,
            onChanged: (value) {
              setState(() => _highQualityRendering = value);
            },
          ),
          _buildDefaultValueTile(
            title: '기본 밝기',
            value: _defaultBrightness,
            min: -0.5,
            max: 0.5,
            onChanged: (value) {
              setState(() => _defaultBrightness = value);
            },
          ),
          _buildDefaultValueTile(
            title: '기본 대비',
            value: _defaultContrast,
            min: 0.5,
            max: 2.0,
            onChanged: (value) {
              setState(() => _defaultContrast = value);
            },
          ),
          _buildDivider(),

          _buildSectionHeader('도구 설정'),
          SwitchListTile(
            title: const Text('주석 저장'),
            subtitle: const Text('측정 및 주석 자동 저장'),
            value: _saveAnnotations,
            onChanged: (value) {
              setState(() => _saveAnnotations = value);
            },
          ),
          _buildDivider(),

          _buildSectionHeader('저장소 설정'),
          ListTile(
            title: const Text('캐시 지우기'),
            subtitle: const Text('임시 파일 삭제'),
            trailing: const Icon(Icons.cleaning_services),
            onTap: () {
              // TODO: 캐시 지우기 로직 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('캐시가 삭제되었습니다'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('모든 데이터 지우기'),
            subtitle: const Text('모든 DICOM 파일 및 설정 초기화'),
            trailing: const Icon(Icons.delete_forever),
            onTap: () {
              // 확인 대화상자 표시
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('모든 데이터 지우기'),
                      content: const Text('모든 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: 모든 데이터 지우기 로직 구현
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('모든 데이터가 삭제되었습니다'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Text(
                            '삭제',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
          _buildDivider(),

          _buildSectionHeader('정보'),
          ListTile(title: const Text('앱 버전'), subtitle: const Text('1.0.0')),
          ListTile(
            title: const Text('개발자'),
            subtitle: const Text('모바일 DICOM 뷰어 팀'),
          ),
          const SizedBox(height: 32),

          // 설정 저장 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('설정 저장'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(indent: 16, endIndent: 16);
  }

  Widget _buildDefaultValueTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  title == '기본 밝기'
                      ? '${(value * 100).toStringAsFixed(0)}%'
                      : '${(value * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

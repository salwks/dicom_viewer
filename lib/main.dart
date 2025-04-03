import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dicom_viewer/data/services/dicom_service.dart';
import 'package:dicom_viewer/data/services/local_storage_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/themes/app_theme.dart';
import 'domain/blocs/app_bloc_observer.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드만 지원
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // BLoC 관찰자 설정
  Bloc.observer = AppBlocObserver();

  // 서비스 인스턴스 생성
  final dicomService = DicomService();
  final storageService = LocalStorageService();

  // 필요한 권한 요청
  await _requestPermissions();

  runApp(MyApp(dicomService: dicomService, storageService: storageService));
}

// 앱에 필요한 권한 요청
Future<void> _requestPermissions() async {
  // Android/iOS에서 필요한 권한 요청
  final permissions = [Permission.storage, Permission.photos];

  // 권한 상태 확인 및 요청
  for (var permission in permissions) {
    final status = await permission.status;
    if (!status.isGranted) {
      await permission.request();
    }
  }
}

class MyApp extends StatefulWidget {
  final DicomService dicomService;
  final LocalStorageService storageService;

  const MyApp({
    super.key,
    required this.dicomService,
    required this.storageService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  // 테마 설정 로드
  Future<void> _loadThemeSettings() async {
    final settings = await widget.storageService.loadSettings();
    setState(() {
      _isDarkMode = settings['isDarkMode'] as bool;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.dicomService),
        RepositoryProvider.value(value: widget.storageService),
      ],
      child: MaterialApp(
        title: 'DICOM 뷰어',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const HomeScreen(),
      ),
    );
  }
}

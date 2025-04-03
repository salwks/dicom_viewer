import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dicom_viewer/data/services/dicom_service.dart';
import 'package:dicom_viewer/data/services/local_storage_service.dart';
import 'core/themes/app_theme.dart';
import 'domain/blocs/app_bloc_observer.dart';
import 'presentation/screens/home_screen.dart';

void main() {
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

  runApp(MyApp(dicomService: dicomService, storageService: storageService));
}

class MyApp extends StatelessWidget {
  final DicomService dicomService;
  final LocalStorageService storageService;

  const MyApp({
    super.key,
    required this.dicomService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: dicomService),
        RepositoryProvider.value(value: storageService),
      ],
      child: MaterialApp(
        title: 'DICOM 뷰어',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // 시스템 테마 따르기
        home: const HomeScreen(),
      ),
    );
  }
}

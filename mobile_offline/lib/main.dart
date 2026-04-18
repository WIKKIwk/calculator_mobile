import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:device_preview/device_preview.dart';
import 'package:path_provider/path_provider.dart';

import 'services/app_local_store.dart';
import 'services/offline_entity_store.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

/// `make run-per` uchun true: DevicePreview ramkasi. `make run` (Android) — false.
const bool kDevicePreview =
    bool.fromEnvironment('DEVICE_PREVIEW', defaultValue: false);

/// Har ekranda tizim paneli orqasi shaffof qolishi (Flutter ba'zan uslubni yo'qotadi).
const SystemUiOverlayStyle kEdgeToEdgeOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
  systemStatusBarContrastEnforced: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(kEdgeToEdgeOverlay);
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  await AppLocalStore.init();
  await OfflineEntityStore.init();

  final app = const CalculatorOfflineApp();
  if (kDevicePreview) {
    runApp(
      DevicePreview(
        enabled: true,
        builder: (context) => app,
      ),
    );
  } else {
    runApp(app);
  }
}

class CalculatorOfflineApp extends StatelessWidget {
  const CalculatorOfflineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hisoblagich',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: kDevicePreview ? DevicePreview.locale(context) : null,
      builder: (context, child) {
        final wrapped = AnnotatedRegion<SystemUiOverlayStyle>(
          value: kEdgeToEdgeOverlay,
          child: child!,
        );
        if (kDevicePreview) {
          return DevicePreview.appBuilder(context, wrapped);
        }
        return wrapped;
      },
      home: const HomeScreen(),
    );
  }
}

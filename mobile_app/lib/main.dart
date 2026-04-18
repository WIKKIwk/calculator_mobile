import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:device_preview/device_preview.dart';
import 'graphql/client.dart';
import 'services/app_local_store.dart';
import 'services/offline_sync.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

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
  await initHiveForFlutter();
  await AppLocalStore.init();
  await OfflineSyncService.flushPendingRecords(GraphQLConfig.client.value);
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const CalculatorApp(),
    ),
  );
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: GraphQLConfig.client,
      child: MaterialApp(
        title: 'Hisoblagich (online)',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        locale: DevicePreview.locale(context),
        builder: (context, child) {
          final wrapped = AnnotatedRegion<SystemUiOverlayStyle>(
            value: kEdgeToEdgeOverlay,
            child: child!,
          );
          return DevicePreview.appBuilder(context, wrapped);
        },
        home: const HomeScreen(),
      ),
    );
  }
}

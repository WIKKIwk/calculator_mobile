import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:device_preview/device_preview.dart';
import 'graphql/client.dart';
import 'services/app_local_store.dart';
import 'services/offline_sync.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        builder: DevicePreview.appBuilder,
        home: const HomeScreen(),
      ),
    );
  }
}

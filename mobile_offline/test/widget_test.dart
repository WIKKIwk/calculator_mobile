import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';

import 'package:calculator_offline/main.dart';
import 'package:calculator_offline/services/app_local_store.dart';
import 'package:calculator_offline/services/offline_entity_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('calc_offline_hive_test');
    Hive.init(dir.path);
    await AppLocalStore.init();
    await OfflineEntityStore.init();
  });

  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorOfflineApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

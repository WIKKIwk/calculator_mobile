import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart' show HiveStore;

import 'package:calculator_app/main.dart';
import 'package:calculator_app/services/app_local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('calc_app_hive_test');
    HiveStore.init(onPath: dir.path);
    await HiveStore.open();
    await AppLocalStore.init();
  });

  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

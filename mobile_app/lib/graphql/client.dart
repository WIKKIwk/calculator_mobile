import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLConfig {
  // Simulator uchun: localhost (iOS) yoki 10.0.2.2 (Android Emulator)
  static const String _host = 'http://localhost:8080/query';

  /// [initHiveForFlutter] dan keyin chaqirilishi kerak — kesh qurilmada saqlanadi.
  static final ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: HttpLink(_host),
      cache: GraphQLCache(store: HiveStore()),
    ),
  );
}

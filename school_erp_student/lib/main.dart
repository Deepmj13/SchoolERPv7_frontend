import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:school_erp_student/app.dart';
import 'package:school_erp_student/core/logging/app_logger.dart';
import 'package:school_erp_student/core/storage/storage_interface.dart';
import 'package:school_erp_student/core/storage/storage_service.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init(level: Level.INFO);

  const secureStorage = FlutterSecureStorage();
  final storage = StorageService(secureStorage);

  if (_sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = 0.1;
      },
      appRunner: () => _runApp(storage),
    );
  } else {
    _runApp(storage);
  }
}

void _runApp(StorageInterface storage) {
  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const SchoolErpStudentApp(),
    ),
  );
}

import 'package:logging/logging.dart';

/// App-wide logger that provides hierarchical loggers per module.
///
/// Usage: AppLogger.api.fine('GET /students completed in 320ms');
class AppLogger {
  AppLogger._();

  static final Logger api = Logger('api');
  static final Logger auth = Logger('auth');
  static final Logger storage = Logger('storage');
  static final Logger ui = Logger('ui');

  /// Call once in main() before any other code.
  static void init({Level level = Level.ALL}) {
    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('[${record.loggerName}] ${record.level.name}: ${record.message}');
      if (record.error != null) {
        // ignore: avoid_print
        print('  => ${record.error}');
      }
    });
  }
}

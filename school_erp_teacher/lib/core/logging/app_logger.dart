import 'package:logging/logging.dart';

class AppLogger {
  AppLogger._();

  static final Logger api = Logger('api');
  static final Logger auth = Logger('auth');
  static final Logger storage = Logger('storage');
  static final Logger ui = Logger('ui');

  static void init({Level level = Level.ALL}) {
    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      print('[${record.loggerName}] ${record.level.name}: ${record.message}');
      if (record.error != null) {
        print('  => ${record.error}');
      }
    });
  }
}

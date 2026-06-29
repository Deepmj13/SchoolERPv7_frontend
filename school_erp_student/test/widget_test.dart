import 'package:flutter_test/flutter_test.dart';
import 'package:school_erp_student/app.dart';
import 'package:school_erp_student/core/storage/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const SchoolErpStudentApp(),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('School ERP'), findsOneWidget);
    expect(find.text('Student Portal'), findsOneWidget);
  });
}

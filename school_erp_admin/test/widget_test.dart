import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/app.dart';
import 'package:school_erp_admin/core/storage/storage_service.dart';
import 'helpers/fake_storage_service.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    final storage = FakeStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const SchoolErpAdminApp(),
      ),
    );

    // Allow GoRouter async redirect and Riverpod async init to settle
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('School ERP'), findsOneWidget);
    expect(find.text('Admin Portal'), findsOneWidget);
  });
}

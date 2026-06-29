import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/features/admin/data/admin_repository.dart';
import 'package:school_erp_admin/features/auth/presentation/providers/auth_state_provider.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AdminRepository(api);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_repository_provider.dart';

class FeesData {
  final List<FeeDetail> structures;
  final List<FeePayment> payments;
  final double totalPaid;
  final double totalPending;

  FeesData({
    this.structures = const [],
    this.payments = const [],
    this.totalPaid = 0,
    this.totalPending = 0,
  });
}

final studentFeesProvider =
    FutureProvider.autoDispose<FeesData>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final studentId = authState.user?.studentId ?? '';

  final raw = await repo.getFees(studentId);

  final structures = (raw['structures'] as List?)
          ?.map((e) => FeeDetail.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [];

  final payments = (raw['payments'] as List?)
          ?.map((e) => FeePayment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [];

  final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
  final totalPending = structures
      .where((s) => !s.paid)
      .fold(0.0, (sum, s) => sum + s.amount);

  return FeesData(
    structures: structures,
    payments: payments,
    totalPaid: totalPaid,
    totalPending: totalPending,
  );
});

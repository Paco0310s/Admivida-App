import 'package:admivida/business/features/cash_shifts/cash_shifts_service.dart';
import 'package:admivida/business/features/cash_shifts/models/cash_shift_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CashShiftsState {
  final bool isLoading;
  final bool isSubmitting;
  final CashShiftModel? activeShift;
  final List<CashShiftModel> history;
  final String? errorMessage;

  const CashShiftsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.activeShift,
    this.history = const [],
    this.errorMessage,
  });

  CashShiftsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    CashShiftModel? activeShift,
    bool clearActiveShift = false,
    List<CashShiftModel>? history,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CashShiftsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      activeShift: clearActiveShift ? null : (activeShift ?? this.activeShift),
      history: history ?? this.history,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CashShiftsNotifier extends Notifier<CashShiftsState> {
  final String businessId;
  CashShiftsNotifier(this.businessId);

  @override
  CashShiftsState build() {
    Future.microtask(loadAll);
    return const CashShiftsState(isLoading: true);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final activeRes = await CashShiftsService.getActiveShift(businessId);
    final historyRes = await CashShiftsService.getBusinessShifts(
      businessId: businessId,
      page: 1,
      limit: 30,
    );

    CashShiftModel? loadedActive;
    List<CashShiftModel> loadedHistory = state.history;
    String? err;

    activeRes.when(
      (failure) => err = failure.message,
      (shift) => loadedActive = shift,
    );

    historyRes.when(
      (failure) => err ??= failure.message,
      (paginated) => loadedHistory = paginated.data,
    );

    state = CashShiftsState(
      isLoading: false,
      isSubmitting: false,
      activeShift: loadedActive,
      history: loadedHistory,
      errorMessage: err,
    );
  }

  Future<String?> openShift({
    required double openingAmount,
    String? accountId,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await CashShiftsService.openShift(
      businessId: businessId,
      openingAmount: openingAmount,
      accountId: accountId,
      notes: notes,
    );

    String? error;
    await result.when(
      (failure) async {
        error = failure.message;
        state = state.copyWith(isSubmitting: false, errorMessage: error);
      },
      (_) async {
        await loadAll();
      },
    );
    return error;
  }

  Future<String?> addMovement({
    required String type,
    required double amount,
    required String concept,
    String? targetShiftId,
  }) async {
    final shiftId = targetShiftId ?? state.activeShift?.id;
    if (shiftId == null) return 'No hay un turno de caja abierto.';

    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await CashShiftsService.addMovement(
      shiftId: shiftId,
      type: type,
      amount: amount,
      concept: concept,
    );

    String? error;
    await result.when(
      (failure) async {
        error = failure.message;
        state = state.copyWith(isSubmitting: false, errorMessage: error);
      },
      (_) async {
        await loadAll();
      },
    );
    return error;
  }

  Future<String?> closeShift({
    required double actualCash,
    String? notes,
    String? targetShiftId,
  }) async {
    final shiftId = targetShiftId ?? state.activeShift?.id;
    if (shiftId == null) return 'No hay un turno de caja abierto.';

    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await CashShiftsService.closeShift(
      shiftId: shiftId,
      actualCash: actualCash,
      notes: notes,
    );

    String? error;
    await result.when(
      (failure) async {
        error = failure.message;
        state = state.copyWith(isSubmitting: false, errorMessage: error);
      },
      (_) async {
        await loadAll();
      },
    );
    return error;
  }
}

final cashShiftsProvider = NotifierProvider.autoDispose
    .family<CashShiftsNotifier, CashShiftsState, String>(
  CashShiftsNotifier.new,
);

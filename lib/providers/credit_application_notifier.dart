import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/credit_application_draft_model.dart';
import '../services/draft_database.dart';
import '../services/offline_queue.dart';
import '../services/supabase_api.dart';
import '../utils/credit_simulator.dart';

class CreditApplicationState {
  final int currentStep;
  final CreditApplicationDraftModel draft;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const CreditApplicationState({
    this.currentStep = 0,
    required this.draft,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  factory CreditApplicationState.initial({Map<String, dynamic>? prefill}) {
    final draft = _draftFromPrefill(prefill);
    return CreditApplicationState(draft: draft);
  }

  static CreditApplicationDraftModel _draftFromPrefill(
      Map<String, dynamic>? prefill) {
    if (prefill == null) return CreditApplicationDraftModel();
    return CreditApplicationDraftModel(
      clientName: prefill['client_name']?.toString() ??
          prefill['name']?.toString() ??
          '',
      clientDni: prefill['dni']?.toString() ?? '',
      clientPhone: prefill['phone']?.toString() ?? '',
      clientEmail: prefill['email']?.toString() ?? '',
      clientAddress: prefill['address']?.toString() ?? '',
      businessName: prefill['business_name']?.toString() ?? '',
      businessSector: prefill['business_sector']?.toString() ?? '',
      businessAddress: prefill['business_address']?.toString() ??
          prefill['address']?.toString() ??
          '',
      monthlyIncome: (prefill['monthly_income'] as num?)?.toDouble() ?? 0,
      businessAgeYears: (prefill['business_age_years'] as num?)?.toInt() ?? 0,
      officerId: prefill['officer_id']?.toString(),
    );
  }

  CreditApplicationState copyWith({
    int? currentStep,
    CreditApplicationDraftModel? draft,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return CreditApplicationState(
      currentStep: currentStep ?? this.currentStep,
      draft: draft ?? this.draft,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class CreditApplicationNotifier extends StateNotifier<CreditApplicationState> {
  final DraftDatabase _db = DraftDatabase();
  final OfflineQueue _queue = OfflineQueue();

  CreditApplicationNotifier({Map<String, dynamic>? prefill})
      : super(CreditApplicationState.initial(prefill: prefill));

  void updateDraft(CreditApplicationDraftModel draft) {
    state = state.copyWith(draft: draft, clearMessages: true);
  }

  void goToStep(int step) {
    if (step < 0 || step > 3) return;
    state = state.copyWith(currentStep: step, clearMessages: true);
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearMessages: true,
      );
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearMessages: true,
      );
    }
  }

  CreditApplicationDraftModel applySimulation(CreditApplicationDraftModel draft) {
    final sim = CreditSimulator.calculate(
      amount: draft.amount,
      termMonths: draft.termMonths,
      teaPercent: draft.tea,
    );
    return draft.copyWith(
      monthlyPayment: sim.monthlyPayment,
      totalInterest: sim.totalInterest,
      totalAmount: sim.totalAmount,
    );
  }

  Future<CreditApplicationDraftModel?> checkResumableDraft(String dni) async {
    if (dni.isEmpty) return null;
    return _db.loadLatestDraftByDni(dni);
  }

  Future<void> resumeDraft(CreditApplicationDraftModel saved) async {
    final withSim = applySimulation(saved);
    state = state.copyWith(
      draft: withSim,
      currentStep: _inferStepFromDraft(withSim),
      successMessage: 'Borrador restaurado',
      clearMessages: false,
    );
  }

  int _inferStepFromDraft(CreditApplicationDraftModel d) {
    if (d.signatureBase64 != null && d.signatureBase64!.isNotEmpty) return 3;
    if (d.amount > 0) return 2;
    if (d.businessName.isNotEmpty || d.monthlyIncome > 0) return 1;
    if (d.clientName.isNotEmpty) return 0;
    return 0;
  }

  Future<void> saveDraftLocal() async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      var draft = applySimulation(state.draft);
      if (draft.id == null || draft.id!.isEmpty) {
        draft = draft.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }
      await _db.saveDraft(draft);
      state = state.copyWith(
        isSaving: false,
        draft: draft,
        successMessage: 'Borrador guardado en el dispositivo',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No se pudo guardar: $e',
      );
    }
  }

  Future<bool> submitApplication() async {
    final draft = state.draft;
    if (draft.signatureBase64 == null || draft.signatureBase64!.isEmpty) {
      state = state.copyWith(errorMessage: 'La firma digital es obligatoria');
      return false;
    }
    if (draft.amount <= 0 || draft.clientName.isEmpty) {
      state = state.copyWith(
          errorMessage: 'Complete los datos antes de enviar');
      return false;
    }

    state = state.copyWith(isLoading: true, clearMessages: true);
    final payload = applySimulation(draft).toSupabasePayload();

    try {
      final result = await createCreditApplication(payload);
      final localId = draft.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _db.markAsSubmitted(
        localId,
        supabaseId: result['id']?.toString(),
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (_) {
      await _queue.enqueue({'payload': payload});
      await saveDraftLocal();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Sin conexión: solicitud encolada para envío',
      );
      return true;
    }
  }
}

final creditApplicationNotifierProvider = StateNotifierProvider.autoDispose
    .family<CreditApplicationNotifier, CreditApplicationState,
        Map<String, dynamic>?>(
  (ref, prefill) => CreditApplicationNotifier(prefill: prefill),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/buro_report_model.dart';
import '../repositories/buro_repository.dart';

class BureauQueryParams {
  final String dni;
  final String clientName;
  final String? clientId;
  final String? officerId;

  const BureauQueryParams({
    required this.dni,
    required this.clientName,
    this.clientId,
    this.officerId,
  });
}

class BureauState {
  final bool isLoading;
  final BuroReportModel? report;
  final String? errorMessage;
  final bool modalShown;

  const BureauState({
    this.isLoading = false,
    this.report,
    this.errorMessage,
    this.modalShown = false,
  });

  BureauState copyWith({
    bool? isLoading,
    BuroReportModel? report,
    String? errorMessage,
    bool? modalShown,
  }) {
    return BureauState(
      isLoading: isLoading ?? this.isLoading,
      report: report ?? this.report,
      errorMessage: errorMessage ?? this.errorMessage,
      modalShown: modalShown ?? this.modalShown,
    );
  }
}

class BureauNotifier extends StateNotifier<BureauState> {
  final BureauQueryParams params;
  final BuroRepository _repo = BuroRepository();

  BureauNotifier(this.params) : super(const BureauState());

  Future<BuroReportModel?> consultar() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final report = await _repo.consultar(
        dni: params.dni,
        clientId: params.clientId,
        clientName: params.clientName,
        officerId: params.officerId,
      );
      state = state.copyWith(isLoading: false, report: report);
      return report;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void markModalShown() {
    state = state.copyWith(modalShown: true);
  }

  Future<BuroReportModel?> refresh() async {
    state = const BureauState();
    return consultar();
  }
}

final bureauNotifierProvider = StateNotifierProvider.autoDispose
    .family<BureauNotifier, BureauState, BureauQueryParams>(
  (ref, params) => BureauNotifier(params),
);

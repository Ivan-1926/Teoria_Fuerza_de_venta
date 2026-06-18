import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_portfolio_model.dart';
import '../repositories/portfolio_repository.dart';
import 'auth_notifier.dart';

class PortfolioState {
  final bool isLoading;
  final List<DailyPortfolioModel> allPortfolio;
  final List<DailyPortfolioModel> filteredPortfolio;
  final String search;
  final String filter; // todos | urgentes | renovaciones | cobranza
  final String? errorMessage;

  const PortfolioState({
    this.isLoading = false,
    this.allPortfolio = const [],
    this.filteredPortfolio = const [],
    this.search = '',
    this.filter = 'todos',
    this.errorMessage,
  });

  int get totalCount => allPortfolio.length;
  int get urgentCount => allPortfolio.where((item) => item.daysOverdue > 0).length;
  int get visitedCount => allPortfolio.where((item) => item.visited).length;

  PortfolioState copyWith({
    bool? isLoading,
    List<DailyPortfolioModel>? allPortfolio,
    List<DailyPortfolioModel>? filteredPortfolio,
    String? search,
    String? filter,
    String? errorMessage,
  }) {
    return PortfolioState(
      isLoading: isLoading ?? this.isLoading,
      allPortfolio: allPortfolio ?? this.allPortfolio,
      filteredPortfolio: filteredPortfolio ?? this.filteredPortfolio,
      search: search ?? this.search,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final PortfolioRepository _repository;
  final AuthNotifier _authNotifier;

  PortfolioNotifier(this._repository, this._authNotifier)
      : super(const PortfolioState());

  Future<void> loadPortfolio() async {
    // 1. Verify active status of advisor first
    final isActive = await _authNotifier.verifyActiveStatus();
    if (!isActive) return;

    final advisorId = _authNotifier.state.advisor?.id ?? '';
    if (advisorId.isEmpty) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.fetchDailyPortfolio(advisorId);
      state = state.copyWith(
        isLoading: false,
        allPortfolio: data,
        filteredPortfolio: _filterList(data, state.search, state.filter),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  void setSearch(String search) {
    state = state.copyWith(
      search: search,
      filteredPortfolio: _filterList(state.allPortfolio, search, state.filter),
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(
      filter: filter,
      filteredPortfolio: _filterList(state.allPortfolio, state.search, filter),
    );
  }

  List<DailyPortfolioModel> _filterList(
      List<DailyPortfolioModel> list, String search, String filter) {
    var result = List<DailyPortfolioModel>.from(list);

    // Filter by search query (case-insensitive name)
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result.where((item) => item.clientName.toLowerCase().contains(q)).toList();
    }

    // Filter by management type
    switch (filter) {
      case 'urgentes':
        result = result.where((item) => item.daysOverdue > 0).toList();
        break;
      case 'renovaciones':
        result = result.where((item) => item.renewalType == 'renovation').toList();
        break;
      case 'cobranza':
        result = result.where((item) => item.renewalType == 'collection').toList();
        break;
    }

    return result;
  }
}

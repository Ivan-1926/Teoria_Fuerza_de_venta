import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../repositories/auth_repository.dart';
import '../repositories/portfolio_repository.dart';
import '../repositories/route_repository.dart';
import 'auth_notifier.dart';
import 'portfolio_notifier.dart';
import 'route_planner_notifier.dart';
import 'client_detail_notifier.dart';
import 'credit_application_notifier.dart';
import 'application_status_notifier.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository(ref.watch(supabaseClientProvider));
});

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository(ref.watch(supabaseClientProvider));
});

// State Notifier providers (ViewModels)
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

final portfolioNotifierProvider = StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  final repo = ref.watch(portfolioRepositoryProvider);
  final auth = ref.watch(authNotifierProvider.notifier);
  return PortfolioNotifier(repo, auth);
});

final routePlannerNotifierProvider = StateNotifierProvider<RoutePlannerNotifier, RoutePlannerState>((ref) {
  final repo = ref.watch(routeRepositoryProvider);
  final auth = ref.watch(authNotifierProvider.notifier);
  return RoutePlannerNotifier(repo, auth);
});

// M3 — Ficha Cliente
final clientDetailNotifierProvider =
    NotifierProvider<ClientDetailNotifier, ClientDetailState>(
  ClientDetailNotifier.new,
);

// M5 — Solicitud de crédito (family en credit_application_notifier.dart)
// M6 — Documentos y buró (families en document_capture_notifier / bureau_notifier)

// Estado de solicitudes (Supabase + fallback demo)
// applicationStatusNotifierProvider en application_status_notifier.dart

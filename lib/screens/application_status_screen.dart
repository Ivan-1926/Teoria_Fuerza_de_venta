import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_model.dart';
import '../providers/application_status_notifier.dart';
import '../providers/providers.dart';
import '../providers/auth_notifier.dart';
import '../theme.dart';
import '../utils/format_utils.dart';
import '../widgets/data_source_banner.dart';

class ApplicationStatusScreen extends ConsumerStatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  ConsumerState<ApplicationStatusScreen> createState() =>
      _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends ConsumerState<ApplicationStatusScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final officerId = ref.read(authNotifierProvider).advisor?.id;
    ref.read(applicationStatusNotifierProvider.notifier).setOfficerId(officerId);
    await ref.read(applicationStatusNotifierProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applicationStatusNotifierProvider);

    return RefreshIndicator(
      onRefresh: _load,
      color: kPrimaryBlue,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _HeaderStats(state: state),
          ),
          SliverToBoxAdapter(
            child: DataSourceBanner(
              isDemo: state.isDemo,
              supabaseReachable: state.supabaseReachable,
            ),
          ),
          SliverToBoxAdapter(child: _FilterChips(state: state)),
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
            )
          else if (state.errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(state.errorMessage!, textAlign: TextAlign.center),
                ),
              ),
            )
          else if (state.filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No hay solicitudes en este filtro',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ApplicationCard(app: state.filtered[i]),
                  childCount: state.filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderStats extends StatelessWidget {
  final ApplicationStatusState state;
  const _HeaderStats({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: kPrimaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado de solicitudes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.applications.length} solicitudes en seguimiento',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                label: 'Enviadas',
                count: state.countByStatus('enviado') + state.countByStatus('pendiente'),
                color: statusSent,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Comité',
                count: state.countByStatus('comite') + state.countByStatus('comité'),
                color: statusCommittee,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Aprobadas',
                count: state.countByStatus('aprobado'),
                color: statusApproved,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color == statusCommittee ? kPrimaryYellow : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  final ApplicationStatusState state;
  const _FilterChips({required this.state});

  static const _filters = [
    ('todos', 'Todas'),
    ('enviado', 'Enviadas'),
    ('comite', 'Comité'),
    ('aprobado', 'Aprobadas'),
    ('desembolsado', 'Desembolso'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _filters.map((f) {
          final selected = state.filter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2),
              selected: selected,
              onSelected: (_) => ref
                  .read(applicationStatusNotifierProvider.notifier)
                  .setFilter(f.$1),
              selectedColor: kPrimaryYellow,
              checkmarkColor: kPrimaryBlue,
              labelStyle: TextStyle(
                color: selected ? kPrimaryBlue : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel app;
  const _ApplicationCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final dateStr = app.submittedAt != null
        ? '${app.submittedAt!.day}/${app.submittedAt!.month}/${app.submittedAt!.year}'
        : '—';
    final initials = app.clientName.isNotEmpty
        ? app.clientName.trim().split(' ').take(2).map((p) => p[0]).join().toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: app.statusColor.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: app.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kPrimaryBlue,
                        ),
                      ),
                      if (app.clientDni != null && app.clientDni!.isNotEmpty)
                        Text(
                          'DNI ${app.clientDni}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        app.purpose,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      FormatUtils.usd(app.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kPrimaryBlue,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: app.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        app.statusLabel,
                        style: TextStyle(
                          color: app.statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusTimeline(currentStep: app.statusStep),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Enviada: $dateStr',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    if (app.monthlyPayment != null)
                      Text(
                        'Cuota ${FormatUtils.usd(app.monthlyPayment!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryBlue,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final int currentStep;
  const _StatusTimeline({required this.currentStep});

  static const _steps = ['Enviado', 'Comité', 'Aprobado', 'Desembolso'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineIndex = i ~/ 2;
          final done = lineIndex < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              color: done ? kPrimaryYellow : Colors.grey.shade300,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final active = stepIndex <= currentStep;
        final current = stepIndex == currentStep;
        return Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? (current ? kPrimaryYellow : kPrimaryBlue) : Colors.grey.shade300,
                border: current
                    ? Border.all(color: kPrimaryBlue, width: 2)
                    : null,
              ),
              child: active
                  ? Icon(
                      current ? Icons.circle : Icons.check,
                      size: current ? 8 : 14,
                      color: current ? kPrimaryBlue : Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              _steps[stepIndex],
              style: TextStyle(
                fontSize: 9,
                fontWeight: current ? FontWeight.bold : FontWeight.normal,
                color: active ? kPrimaryBlue : Colors.grey,
              ),
            ),
          ],
        );
      }),
    );
  }
}

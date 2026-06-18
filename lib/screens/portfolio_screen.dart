import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../utils/format_utils.dart';
import '../models/daily_portfolio_model.dart';
import '../providers/providers.dart';
import 'client_detail_screen.dart';
import 'new_application_screen.dart';
import 'queued_screen.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    // Load portfolio data on launch
    Future.microtask(() => ref.read(portfolioNotifierProvider.notifier).loadPortfolio());
  }

  @override
  Widget build(BuildContext context) {
    final today = FormatUtils.datePortfolioHeader(DateTime.now());
    final authState = ref.watch(authNotifierProvider);
    final portfolioState = ref.watch(portfolioNotifierProvider);
    
    final officerFirstName = authState.advisor?.nombres.split(' ').first ?? 'Asesor';

    return Scaffold(
      backgroundColor: kBackground,
      body: RefreshIndicator(
        onRefresh: () => ref.read(portfolioNotifierProvider.notifier).loadPortfolio(),
        color: kPrimaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: kPrimaryBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hola, $officerFirstName 👋',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Cartera · ${today.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _Stat(
                          icon: Icons.people,
                          label: '${portfolioState.totalCount}',
                          sub: 'Total',
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        _Stat(
                          icon: Icons.warning_amber,
                          label: '${portfolioState.urgentCount}',
                          sub: 'Urgentes',
                          color: kPrimaryYellow,
                        ),
                        const SizedBox(width: 10),
                        _Stat(
                          icon: Icons.check_circle_outline,
                          label: '${portfolioState.visitedCount}',
                          sub: 'Visitados',
                          color: const Color(0xFF66BB6A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente…',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => ref.read(portfolioNotifierProvider.notifier).setSearch(v),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _Chip(
                      label: 'Todos',
                      value: 'todos',
                      sel: portfolioState.filter,
                      onTap: (v) => ref.read(portfolioNotifierProvider.notifier).setFilter(v),
                    ),
                    _Chip(
                      label: 'Urgentes',
                      value: 'urgentes',
                      sel: portfolioState.filter,
                      onTap: (v) => ref.read(portfolioNotifierProvider.notifier).setFilter(v),
                    ),
                    _Chip(
                      label: 'Renovaciones',
                      value: 'renovaciones',
                      sel: portfolioState.filter,
                      onTap: (v) => ref.read(portfolioNotifierProvider.notifier).setFilter(v),
                    ),
                    _Chip(
                      label: 'Cobranza',
                      value: 'cobranza',
                      sel: portfolioState.filter,
                      onTap: (v) => ref.read(portfolioNotifierProvider.notifier).setFilter(v),
                    ),
                  ],
                ),
              ),
            ),
            if (portfolioState.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (portfolioState.errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(portfolioState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => ref.read(portfolioNotifierProvider.notifier).loadPortfolio(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else if (portfolioState.filteredPortfolio.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text('No hay clientes para este filtro',
                      style: TextStyle(color: Colors.grey.shade500)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ClientCard(
                      item: portfolioState.filteredPortfolio[i],
                    ),
                    childCount: portfolioState.filteredPortfolio.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'queue',
            backgroundColor: Colors.white,
            foregroundColor: kPrimaryBlue,
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const QueuedScreen())),
            child: const Icon(Icons.cloud_upload_outlined),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'new',
            icon: const Icon(Icons.add),
            label: const Text('Nueva solicitud'),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const NewApplicationScreen())),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;

  const _Stat({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                  Text(sub,
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value, sel;
  final ValueChanged<String> onTap;

  const _Chip({
    required this.label,
    required this.value,
    required this.sel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == sel;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kPrimaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? kPrimaryBlue : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade700,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final DailyPortfolioModel item;

  const _ClientCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final name = item.clientName;
    final balance = item.loanBalance;
    final overdue = item.daysOverdue;
    final date = item.nextVisitDate;
    final purpose = item.purpose ?? 'Crédito';
    final urgent = overdue > 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientDetailScreen(client: item.toMap()),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
          border: urgent ? Border.all(color: Colors.red.shade300, width: 1.5) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: urgent ? Colors.red.shade50 : const Color(0xFFE8F0FE),
                radius: 26,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: TextStyle(
                      color: urgent ? Colors.red.shade700 : kPrimaryBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: kPrimaryBlue,
                            ),
                          ),
                        ),
                        if (urgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$overdue días',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                        if (item.visited)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('VISITADO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(purpose, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(FormatUtils.usd(balance),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: kPrimaryBlue,
                            )),
                        const Spacer(),
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

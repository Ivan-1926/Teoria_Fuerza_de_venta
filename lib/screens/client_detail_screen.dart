import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/format_utils.dart';
import '../models/client_profile_model.dart';
import '../providers/providers.dart';
import '../theme.dart';
import 'new_application_screen.dart';
import 'document_capture_screen.dart';
import 'bureau_screen.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(clientDetailNotifierProvider.notifier).loadProfileFromMap(widget.client);
    });
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsapp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientDetailNotifierProvider);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: kBackground,
      body: state.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
          : state.errorMessage != null && profile == null
              ? _ErrorView(message: state.errorMessage!, onRetry: () {
                  ref.read(clientDetailNotifierProvider.notifier)
                      .loadProfileFromMap(widget.client);
                })
              : _buildBody(context, profile!, state.creditHistory),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ClientProfileModel profile,
    List<Map<String, dynamic>> history,
  ) {
    final officerId = ref.watch(authNotifierProvider).advisor?.id;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: kPrimaryBlue,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF001F4D), Color(0xFF004B8D)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: kPrimaryYellow,
                            child: Text(
                              profile.initials,
                              style: const TextStyle(
                                color: kPrimaryBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (profile.dni.isNotEmpty)
                                  Text(
                                    'DNI: ${profile.dni}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _SemaphoreChip(profile: profile),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _HeaderAction(
                            icon: Icons.phone,
                            label: 'Llamar',
                            enabled: profile.phone.isNotEmpty,
                            onTap: () => _call(profile.phone),
                          ),
                          const SizedBox(width: 10),
                          _HeaderAction(
                            icon: Icons.chat,
                            label: 'WhatsApp',
                            enabled: profile.phone.isNotEmpty,
                            onTap: () => _whatsapp(profile.phone),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (profile.hasPreApprovedOffer)
                  _PreApprovedBanner(
                    amount: profile.preApprovedAmount,
                    onApply: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewApplicationScreen(
                          prefillClient: profile.toMap(),
                        ),
                      ),
                    ),
                  ),
                if (profile.hasPreApprovedOffer) const SizedBox(height: 12),
                _SectionTitle('Datos personales'),
                _InfoCard(children: [
                  _InfoRow(Icons.badge, 'DNI', profile.dni),
                  _InfoRow(Icons.phone, 'Teléfono', profile.phone),
                  _InfoRow(Icons.email, 'Correo', profile.email),
                  _InfoRow(Icons.location_on, 'Dirección', profile.address),
                ]),
                const SizedBox(height: 12),
                _SectionTitle('Datos del negocio'),
                _InfoCard(children: [
                  _InfoRow(Icons.store, 'Negocio', profile.businessName),
                  _InfoRow(Icons.category, 'Rubro', profile.businessSector),
                  _InfoRow(Icons.place, 'Ubicación', profile.businessAddress),
                  _InfoRow(
                    Icons.payments,
                    'Ingreso mensual',
                    FormatUtils.usd(profile.monthlyIncome),
                    highlight: true,
                  ),
                  if (profile.businessAgeYears > 0)
                    _InfoRow(
                      Icons.schedule,
                      'Antigüedad',
                      '${profile.businessAgeYears} años',
                    ),
                ]),
                const SizedBox(height: 12),
                _SectionTitle('Score SBS'),
                _SbsScoreCard(profile: profile),
                const SizedBox(height: 12),
                _SectionTitle('Créditos vigentes'),
                if (profile.activeCredits.isEmpty)
                  const _EmptyHint('Sin créditos vigentes registrados')
                else
                  ...profile.activeCredits.map(
                    (c) => _CreditTile(app: c),
                  ),
                const SizedBox(height: 12),
                _SectionTitle('Historial crediticio'),
                if (history.isEmpty)
                  const _EmptyHint('Sin movimientos en historial')
                else
                  ...history.map(
                    (c) => _CreditTile(app: c),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.add_circle_outline,
                        label: 'Nueva solicitud',
                        color: kPrimaryBlue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewApplicationScreen(
                              prefillClient: profile.toMap(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.credit_score,
                        label: 'Buró',
                        color: const Color(0xFF00796B),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BureauScreen(
                              dni: profile.dni,
                              clientName: profile.name,
                              clientId: profile.id,
                              officerId: officerId,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _ActionBtn(
                    icon: Icons.camera_alt_outlined,
                    label: 'Documentos',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentCaptureScreen(
                          clientId: profile.id,
                          clientDni: profile.dni,
                          clientName: profile.name,
                          officerId: officerId,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
}

class _SemaphoreChip extends StatelessWidget {
  final ClientProfileModel profile;
  const _SemaphoreChip({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: profile.semaphoreColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            profile.semaphoreStatus == 'green'
                ? Icons.circle
                : profile.semaphoreStatus == 'yellow'
                    ? Icons.circle
                    : Icons.circle,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            profile.semaphoreLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: enabled ? kPrimaryYellow : Colors.white24,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: kPrimaryBlue, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: enabled ? kPrimaryBlue : Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreApprovedBanner extends StatelessWidget {
  final double amount;
  final VoidCallback onApply;
  const _PreApprovedBanner({
    required this.amount,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryYellow, kPrimaryYellow.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryYellow.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: kPrimaryBlue, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Oferta preaprobada',
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Hasta ${FormatUtils.usd(amount)}',
                  style: const TextStyle(color: kPrimaryBlue, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: kPrimaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  const _InfoRow(this.icon, this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: kPrimaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SbsScoreCard extends StatelessWidget {
  final ClientProfileModel profile;
  const _SbsScoreCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: profile.semaphoreColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: profile.semaphoreColor, width: 3),
            ),
            child: Center(
              child: Text(
                '${profile.creditScore}',
                style: TextStyle(
                  color: profile.semaphoreColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.scoreLabel,
                  style: TextStyle(
                    color: profile.semaphoreColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Semáforo SBS · ${profile.semaphoreLabel}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Light(color: const Color(0xFF2E7D32), on: profile.creditScore >= 700),
                    const SizedBox(width: 6),
                    _Light(color: kPrimaryYellow, on: profile.creditScore >= 500 && profile.creditScore < 700),
                    const SizedBox(width: 6),
                    _Light(color: const Color(0xFFC62828), on: profile.creditScore < 500),
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

class _Light extends StatelessWidget {
  final Color color;
  final bool on;
  const _Light({required this.color, required this.on});
  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: on ? color : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      );
}

class _CreditTile extends StatelessWidget {
  final Map<String, dynamic> app;
  const _CreditTile({required this.app});

  @override
  Widget build(BuildContext context) {
    final amount = (app['amount'] as num?)?.toDouble() ?? 0;
    final status = app['status']?.toString() ?? '';
    final purpose = app['purpose']?.toString() ?? '';
    final date = app['submitted_at']?.toString().substring(0, 10) ?? '';
    final color = applicationStatusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.account_balance, color: color, size: 20),
        ),
        title: Text(
          FormatUtils.usd(amount),
          style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue),
        ),
        subtitle: Text('$purpose · $date'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

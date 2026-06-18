import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/buro_report_model.dart';
import '../utils/format_utils.dart';
import '../providers/bureau_notifier.dart';
import '../theme.dart';

class BureauScreen extends ConsumerStatefulWidget {
  final String dni;
  final String clientName;
  final String? clientId;
  final String? officerId;

  const BureauScreen({
    super.key,
    required this.dni,
    required this.clientName,
    this.clientId,
    this.officerId,
  });

  @override
  ConsumerState<BureauScreen> createState() => _BureauScreenState();
}

class _BureauScreenState extends ConsumerState<BureauScreen> {
  BureauQueryParams get _params => BureauQueryParams(
        dni: widget.dni,
        clientName: widget.clientName,
        clientId: widget.clientId,
        officerId: widget.officerId,
      );

  @override
  void initState() {
    super.initState();
    Future.microtask(_runConsulta);
  }

  Future<void> _runConsulta() async {
    final report =
        await ref.read(bureauNotifierProvider(_params).notifier).consultar();
    if (!mounted || report == null) return;
    _showResultModal(report);
  }

  void _showResultModal(BuroReportModel report, {bool force = false}) {
    final notifier = ref.read(bureauNotifierProvider(_params).notifier);
    if (!force && ref.read(bureauNotifierProvider(_params)).modalShown) return;
    notifier.markModalShown();

    if (report.inBlacklist) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.shade700, width: 2),
            ),
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red.shade800, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'LISTA NEGRA',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El cliente ${report.clientName} no puede continuar el proceso.',
                  style: TextStyle(color: Colors.red.shade900),
                ),
                const SizedBox(height: 12),
                if (report.blacklistReason != null)
                  Text(
                    'Motivo: ${report.blacklistReason}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade800,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'DNI: ${report.dni}',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Cerrar — Bloqueado'),
              ),
            ],
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.green.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green.shade600, width: 2),
          ),
          title: Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green.shade800, size: 32),
              const SizedBox(width: 10),
              Text(
                'Sin restricciones',
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'El cliente no figura en listas negras. Puede continuar con la evaluación crediticia.',
            style: TextStyle(color: Colors.green.shade900),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    }
  }

  Color _scoreColor(int score) {
    if (score >= 700) return const Color(0xFF2E7D32);
    if (score >= 500) return kPrimaryYellow;
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bureauNotifierProvider(_params));
    final report = state.report;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Consulta de Buró'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () async {
                    final report = await ref
                        .read(bureauNotifierProvider(_params).notifier)
                        .refresh();
                    if (!mounted || report == null) return;
                    _showResultModal(report, force: true);
                  },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kPrimaryBlue),
                  SizedBox(height: 16),
                  Text('Consultando buró y listas negras...'),
                ],
              ),
            )
          : state.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(state.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _runConsulta,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : report == null
                  ? const Center(child: Text('Sin datos'))
                  : _buildReport(report),
    );
  }

  Widget _buildReport(BuroReportModel report) {
    final scoreColor = _scoreColor(report.calificacionSbs);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.clientName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
                Text(
                  'DNI: ${report.dni}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Divider(height: 24),
                Text(
                  'Consulta: ${report.consultedAt.toString().substring(0, 16)}',
                  style: const TextStyle(fontSize: 12, color: kPrimaryBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (report.inBlacklist)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade800),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cliente en LISTA NEGRA',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade800),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Sin coincidencias en listas negras',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Center(
            child: _card(
              child: Column(
                children: [
                  const Text(
                    'CALIFICACIÓN SBS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${report.calificacionSbs}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    report.calificacionSbsLabel,
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Indicadores de deuda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          _metricRow('Deuda total', FormatUtils.usd(report.deudaTotal)),
          _metricRow('Mayor deuda', FormatUtils.usd(report.mayorDeuda)),
          _metricRow(
            'Días de mora',
            '${report.diasMora} días',
            highlight: report.diasMora > 0,
            danger: report.diasMora > 30,
          ),
          if (report.supabaseId != null) ...[
            const SizedBox(height: 24),
            Text(
              'Registro guardado en Supabase',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _metricRow(
    String label,
    String value, {
    bool highlight = false,
    bool danger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: danger
                  ? Colors.red.shade700
                  : highlight
                      ? kPrimaryBlue
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

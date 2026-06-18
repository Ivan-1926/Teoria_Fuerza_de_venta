import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_model.dart';
import '../providers/application_status_notifier.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../utils/format_utils.dart';

/// Acciones de campo para el **asesor** en la app móvil.
/// Aprobar / rechazar / desembolsar quedan en la web del supervisor.
class ApplicationActionButtons extends ConsumerWidget {
  final ApplicationModel app;
  final bool updating;
  final bool compact;

  const ApplicationActionButtons({
    super.key,
    required this.app,
    this.updating = false,
    this.compact = false,
  });

  Future<void> _confirmAndRun(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required Future<String?> Function() action,
    required String successMessage,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await action();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: statusApproved),
      );
    }
  }

  Future<String?> _review(WidgetRef ref, String status) {
    return ref
        .read(applicationStatusNotifierProvider.notifier)
        .reviewApplication(app.id, status);
  }

  Future<String?> _accept(WidgetRef ref) {
    final officerId = ref.read(authNotifierProvider).advisor?.id;
    if (officerId == null || officerId.isEmpty) {
      return Future.value('No hay asesor en sesión.');
    }
    return ref
        .read(applicationStatusNotifierProvider.notifier)
        .acceptApplication(app.id, officerId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (updating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(color: kPrimaryBlue),
        ),
      );
    }

    if (app.hasFieldActions) {
      if (app.needsAcceptance) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmAndRun(
              context,
              ref,
              title: 'Aceptar solicitud',
              message:
                  '¿Tomar la solicitud de ${app.clientName} por ${FormatUtils.usd(app.amount)}?',
              confirmLabel: 'Aceptar',
              confirmColor: kPrimaryBlue,
              action: () => _accept(ref),
              successMessage: 'Solicitud aceptada — continúa el seguimiento en campo',
            ),
            icon: const Icon(Icons.inbox, size: 18),
            label: const Text('Aceptar solicitud'),
          ),
        );
      }

      if (app.canSendToCommittee && !app.isUnassigned) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmAndRun(
              context,
              ref,
              title: 'Enviar a comité',
              message:
                  '¿Enviar la solicitud de ${app.clientName} a evaluación del supervisor?',
              confirmLabel: 'Enviar a comité',
              confirmColor: statusCommittee,
              action: () => _review(ref, 'comite'),
              successMessage: 'Enviada a comité — el supervisor decide en la web',
            ),
            icon: const Icon(Icons.groups_outlined, size: 18),
            label: Text(compact ? 'Enviar a comité' : 'Enviar a comité (supervisor)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: statusCommittee,
              side: const BorderSide(color: statusCommittee),
            ),
          ),
        );
      }
    }

    if (app.awaitsSupervisorDecision) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusCommittee.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusCommittee.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.laptop_mac, size: 18, color: statusCommittee),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'En comité — el supervisor aprueba o rechaza desde la web.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
      );
    }

    if (app.status.toLowerCase() == 'aprobado') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusApproved.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 18, color: statusApproved),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aprobada por supervisor — el crédito se refleja en la app del cliente.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';

/// Indica si los datos vienen de Supabase en vivo o del modo demo.
class DataSourceBanner extends StatelessWidget {
  final bool isDemo;
  final bool supabaseReachable;

  const DataSourceBanner({
    super.key,
    required this.isDemo,
    required this.supabaseReachable,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color bg;
    final Color fg;
    final String title;
    final String subtitle;

    if (!supabaseReachable) {
      icon = Icons.cloud_off;
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
      title = 'Sin conexión a Supabase';
      subtitle =
          'Modo demo offline — enviar a comité no llegará a la web del supervisor';
    } else {
      icon = Icons.cloud_done;
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      title = 'Datos en vivo';
      subtitle = 'Sincronizado con Supabase · fv_credit_applications';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: fg,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

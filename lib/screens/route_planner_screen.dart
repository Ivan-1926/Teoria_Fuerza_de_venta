import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../utils/format_utils.dart';
import '../models/route_visit_model.dart';
import '../providers/providers.dart';

class RoutePlannerScreen extends ConsumerStatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  ConsumerState<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends ConsumerState<RoutePlannerScreen> {
  final _todayLabel = FormatUtils.dateRouteHeader(DateTime.now());
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(routePlannerNotifierProvider.notifier).loadRoutePlanner());
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _openExternalNavigation(RouteVisitModel visit, String appName) async {
    final lat = visit.lat;
    final lng = visit.lng;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación del cliente no disponible para navegación.')),
      );
      return;
    }

    Uri uri;
    if (appName.toLowerCase() == 'waze') {
      uri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    } else {
      // Google Maps intent (google.navigation) or fallback geo:
      uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      } else {
        // Fallback to web URLs
        final fallbackUri = appName.toLowerCase() == 'waze'
            ? Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes')
            : Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('No URL can be launched');
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir la aplicación de $appName.')),
        );
      }
    }
  }

  Future<void> _openFullRoute(List<RouteVisitModel> visits) async {
    final mappedVisits = visits.where((v) => v.lat != null && v.lng != null).toList();
    if (mappedVisits.isEmpty) return;

    final waypoints = mappedVisits.map((v) => '${v.lat},${v.lng}').join('|');
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&waypoints=$waypoints');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps.')),
        );
      }
    }
  }

  void _showNavigationOptions(RouteVisitModel visit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona Aplicación de Navegación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.map, color: Color(0xFF0F9D58), size: 28),
              title: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _openExternalNavigation(visit, 'google');
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Color(0xFF33CCFF), size: 28),
              title: const Text('Waze', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _openExternalNavigation(visit, 'waze');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(routePlannerNotifierProvider);
    final total = routeState.visits.length;
    final done = routeState.visits.where((v) => v.visitStatus == 'visited').length;
    final pending = routeState.visits.where((v) => v.visitStatus == 'pending').length;

    // Camera Center: defaults to advisor current position or Quito
    final initialCenter = routeState.currentPosition != null
        ? LatLng(routeState.currentPosition!.latitude, routeState.currentPosition!.longitude)
        : const LatLng(-0.180653, -78.467838);

    // Sync camera if controller is initialized and position changes
    if (_mapController != null && routeState.currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(routeState.currentPosition!.latitude, routeState.currentPosition!.longitude),
          14.0,
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: RefreshIndicator(
        onRefresh: () => ref.read(routePlannerNotifierProvider.notifier).loadRoutePlanner(),
        color: kPrimaryBlue,
        child: Column(
          children: [
            // ── Header Block ──────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: kPrimaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Planificación de Ruta',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(_todayLabel.toUpperCase(),
                      style: const TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatBadge(label: '$total', sub: 'Total visitas', color: Colors.white),
                      const SizedBox(width: 10),
                      _StatBadge(label: '$done', sub: 'Completadas', color: const Color(0xFF66BB6A)),
                      const SizedBox(width: 10),
                      _StatBadge(label: '$pending', sub: 'Pendientes', color: kPrimaryYellow),
                    ],
                  ),
                ],
              ),
            ),

            // ── Interactive Map Box ────────────────────────────────────
            Container(
              height: 230,
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: routeState.isLoading && routeState.visits.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: initialCenter,
                          zoom: 13.0,
                        ),
                        markers: routeState.markers,
                        polylines: routeState.polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
              ),
            ),

            // ── Optimizar Ruta Banner ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: routeState.isLoading
                          ? null
                          : () => ref.read(routePlannerNotifierProvider.notifier).optimizeRoute(),
                      icon: const Icon(Icons.electric_bolt, size: 16),
                      label: const Text('Optimizar Ruta (Distancia TSP)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _openFullRoute(routeState.visits),
                    tooltip: 'Ruta Completa en Maps',
                    icon: const Icon(Icons.directions),
                    color: kPrimaryBlue,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shadowColor: Colors.black12,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Visit List ─────────────────────────────────────────────
            Expanded(
              child: routeState.isLoading && routeState.visits.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : routeState.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(routeState.errorMessage!,
                                  style: TextStyle(color: Colors.grey.shade500)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(routePlannerNotifierProvider.notifier)
                                    .loadRoutePlanner(),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : routeState.visits.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
                                  const SizedBox(height: 10),
                                  Text('Sin visitas programadas para hoy.',
                                      style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: routeState.visits.length,
                              itemBuilder: (ctx, i) {
                                final visit = routeState.visits[i];
                                return _VisitTile(
                                  visit: visit,
                                  index: i,
                                  total: routeState.visits.length,
                                  onMarkVisited: () => ref
                                      .read(routePlannerNotifierProvider.notifier)
                                      .markAsVisited(visit.id),
                                  onOpenMaps: () => _showNavigationOptions(visit),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, sub;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  final RouteVisitModel visit;
  final int index, total;
  final VoidCallback onMarkVisited, onOpenMaps;

  const _VisitTile({
    required this.visit,
    required this.index,
    required this.total,
    required this.onMarkVisited,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    final name = visit.clientName;
    final address = visit.address;
    final time = visit.estimatedTime ?? '';
    final isDone = visit.visitStatus == 'visited';
    final isLast = index == total - 1;
    final notes = visit.notes ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone ? Colors.green : kPrimaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (isDone ? Colors.green : kPrimaryBlue).withOpacity(0.4),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          )),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? Colors.green.withOpacity(0.4) : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              decoration: BoxDecoration(
                color: isDone ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDone ? Colors.grey : kPrimaryBlue,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kPrimaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(time,
                                style: const TextStyle(
                                  color: kPrimaryBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                      ],
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(notes,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          )),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onOpenMaps,
                            icon: const Icon(Icons.navigation_outlined, size: 14),
                            label: const Text('Navegar', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              side: const BorderSide(color: kPrimaryBlue),
                              foregroundColor: kPrimaryBlue,
                            ),
                          ),
                        ),
                        if (!isDone) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onMarkVisited,
                              icon: const Icon(Icons.check, size: 14),
                              label: const Text('Completar', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
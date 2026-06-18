import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/format_utils.dart';
import '../models/route_visit_model.dart';
import '../repositories/route_repository.dart';
import 'auth_notifier.dart';

class RoutePlannerState {
  final bool isLoading;
  final List<RouteVisitModel> visits;
  final Position? currentPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String? errorMessage;

  const RoutePlannerState({
    this.isLoading = false,
    this.visits = const [],
    this.currentPosition,
    this.markers = const {},
    this.polylines = const {},
    this.errorMessage,
  });

  RoutePlannerState copyWith({
    bool? isLoading,
    List<RouteVisitModel>? visits,
    Position? currentPosition,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    String? errorMessage,
  }) {
    return RoutePlannerState(
      isLoading: isLoading ?? this.isLoading,
      visits: visits ?? this.visits,
      currentPosition: currentPosition ?? this.currentPosition,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RoutePlannerNotifier extends StateNotifier<RoutePlannerState> {
  final RouteRepository _repository;
  final AuthNotifier _authNotifier;

  RoutePlannerNotifier(this._repository, this._authNotifier)
      : super(const RoutePlannerState());

  Future<void> loadRoutePlanner() async {
    // 1. Verify active advisor status
    final isActive = await _authNotifier.verifyActiveStatus();
    if (!isActive) return;

    final advisorId = _authNotifier.state.advisor?.id ?? '';
    if (advisorId.isEmpty) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 2. Fetch current geolocation
      Position? position;
      try {
        position = await _determinePosition();
      } catch (_) {
        // Fallback mock position (Quito Center) for emulation or denied permission
        position = Position(
          latitude: -0.180653,
          longitude: -78.467838,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 2850.0,
          altitudeAccuracy: 1.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 1.0,
        );
      }

      // 3. Fetch visits from Supabase
      final todayStr = FormatUtils.dateYmd(DateTime.now());
      final data = await _repository.fetchRouteVisits(todayStr, officerId: advisorId);

      state = state.copyWith(
        isLoading: false,
        visits: data,
        currentPosition: position,
      );

      // 4. Build Markers and Polylines
      _buildMapLayers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  Future<void> markAsVisited(String visitId) async {
    try {
      if (!visitId.startsWith('rv-demo-')) {
        await _repository.updateVisitStatus(visitId, 'visited');
      }
      
      // Update local status
      final updatedVisits = state.visits.map((v) {
        if (v.id == visitId) {
          return v.copyWith(visitStatus: 'visited');
        }
        return v;
      }).toList();

      state = state.copyWith(visits: updatedVisits);
      _buildMapLayers();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al marcar como completado: $e');
    }
  }

  Future<void> optimizeRoute() async {
    final pos = state.currentPosition;
    if (pos == null || state.visits.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final List<RouteVisitModel> locVisits = state.visits.where((v) => v.lat != null && v.lng != null).toList();
      final List<RouteVisitModel> unmappedVisits = state.visits.where((v) => v.lat == null || v.lng == null).toList();
      
      if (locVisits.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Nearest Neighbor Algorithm
      final List<RouteVisitModel> optimized = [];
      double currentLat = pos.latitude;
      double currentLng = pos.longitude;

      while (locVisits.isNotEmpty) {
        int bestIndex = 0;
        double minDistance = double.maxFinite;

        for (int i = 0; i < locVisits.length; i++) {
          final visit = locVisits[i];
          final dist = _haversineDistance(
            currentLat,
            currentLng,
            visit.lat!,
            visit.lng!,
          );
          if (dist < minDistance) {
            minDistance = dist;
            bestIndex = i;
          }
        }

        final nextVisit = locVisits.removeAt(bestIndex);
        optimized.add(nextVisit);
        currentLat = nextVisit.lat!;
        currentLng = nextVisit.lng!;
      }

      // Add unmapped back to the end
      optimized.addAll(unmappedVisits);

      // Save orders in Supabase (omit demo visits)
      final persistable = optimized.where((v) => !v.id.startsWith('rv-demo-')).toList();
      if (persistable.isNotEmpty) {
        await _repository.saveOptimizedRouteOrder(persistable);
      }

      // Update local state visits with ordered tags
      final reordered = optimized.asMap().entries.map((entry) {
        return entry.value.copyWith(visitOrder: entry.key + 1);
      }).toList();

      state = state.copyWith(isLoading: false, visits: reordered);
      _buildMapLayers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al optimizar ruta: ${e.toString()}',
      );
    }
  }

  void _buildMapLayers() {
    final Set<Marker> markers = {};
    final List<LatLng> polylinePoints = [];

    final pos = state.currentPosition;
    if (pos != null) {
      // 1. Advisor Current Location Marker
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(pos.latitude, pos.longitude),
          infoWindow: const InfoWindow(title: 'Mi Ubicación Actual'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
      polylinePoints.add(LatLng(pos.latitude, pos.longitude));
    }

    // 2. Add client markers and construct polyline path
    for (final visit in state.visits) {
      if (visit.lat != null && visit.lng != null) {
        final point = LatLng(visit.lat!, visit.lng!);
        polylinePoints.add(point);

        final isVisited = visit.visitStatus == 'visited';
        markers.add(
          Marker(
            markerId: MarkerId(visit.id),
            position: point,
            infoWindow: InfoWindow(
              title: '#${visit.visitOrder} - ${visit.clientName}',
              snippet: visit.address,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isVisited ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    // 3. Create route path polyline
    final Set<Polyline> polylines = {};
    if (polylinePoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_path'),
          points: polylinePoints,
          color: const Color(0xFF003F7D), // Pichincha Blue
          width: 5,
          jointType: JointType.round,
        ),
      );
    }

    state = state.copyWith(markers: markers, polylines: polylines);
  }

  // Geolocator permissions checking helper
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Los servicios de ubicación están desactivados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Los permisos de ubicación están denegados permanentemente.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Haversine formula calculation (spherical distance in kilometers)
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }
}

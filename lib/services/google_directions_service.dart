import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/maps_config.dart';

class GoogleDirectionsService {
  /// Obtiene la ruta en auto entre paradas usando Directions API.
  static Future<List<LatLng>> fetchDrivingRoute(List<LatLng> stops) async {
    if (stops.length < 2) return [];

    final origin = '${stops.first.latitude},${stops.first.longitude}';
    final destination = '${stops.last.latitude},${stops.last.longitude}';

    final params = <String, String>{
      'origin': origin,
      'destination': destination,
      'mode': 'driving',
      'key': kGoogleMapsApiKey,
    };

    if (stops.length > 2) {
      final waypoints = stops
          .sublist(1, stops.length - 1)
          .map((p) => '${p.latitude},${p.longitude}')
          .join('|');
      params['waypoints'] = waypoints;
    }

    final uri = Uri.parse(kGoogleDirectionsBaseUrl).replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Directions HTTP ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final status = json['status']?.toString() ?? 'UNKNOWN';
    if (status != 'OK') {
      throw Exception('Directions: $status');
    }

    final routes = json['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return [];

    final overview = routes.first['overview_polyline']?['points']?.toString();
    if (overview == null || overview.isEmpty) return [];

    return _decodePolyline(overview);
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}

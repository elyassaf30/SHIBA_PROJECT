import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class OsrmRouteResult {
  final List<LatLng> polylinePoints;
  final double distanceMeters;
  final double durationSeconds;

  const OsrmRouteResult({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} ק"מ';
    }
    return '${distanceMeters.round()} מ׳';
  }

  String get formattedDuration {
    final totalMinutes = (durationSeconds / 60).round();
    if (totalMinutes < 60) return '$totalMinutes דק׳';
    final hours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    return remainingMinutes == 0 ? '$hours שע׳' : '$hours שע׳ $remainingMinutes דק׳';
  }
}

class MapService {
  static const _osrmBaseUrl = 'https://router.project-osrm.org/route/v1/foot';
  static const _requestTimeout = Duration(seconds: 10);

  /// Fetches a walking route from [origin] to [destination] using the public OSRM API.
  /// Returns null if the request fails or no route is found.
  static Future<OsrmRouteResult?> fetchWalkingRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      // OSRM expects coordinates in longitude,latitude order
      final url = Uri.parse(
        '$_osrmBaseUrl'
        '/${origin.longitude},${origin.latitude}'
        ';${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline',
      );

      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        debugPrint('OSRM returned status ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final code = json['code'] as String?;
      if (code != 'Ok') {
        debugPrint('OSRM error code: $code');
        return null;
      }

      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final distance = (route['distance'] as num).toDouble();
      final duration = (route['duration'] as num).toDouble();
      final encodedGeometry = route['geometry'] as String;

      final points = _decodePolyline(encodedGeometry);
      if (points.isEmpty) return null;

      return OsrmRouteResult(
        polylinePoints: points,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } catch (e) {
      debugPrint('OSRM route fetch failed: $e');
      return null;
    }
  }

  /// Decodes a Google-format encoded polyline string into a list of [LatLng] points.
  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

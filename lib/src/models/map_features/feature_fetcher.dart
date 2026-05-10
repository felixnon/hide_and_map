import 'dart:convert';
import 'dart:developer';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'map_poi.dart';
import 'map_overlay.dart';
import 'poi_categories.dart';
import 'station.dart';

class FeatureFetcher {
  static const List<String> _overpassUrls = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];
  static const int _attemptsPerEndpoint = 2;
  static const Duration _requestTimeout = Duration(seconds: 60);

  static Future<List<Map<String, dynamic>>> _fetchElements(String query) async {
    Object? lastError;

    for (final url in _overpassUrls) {
      for (var attempt = 1; attempt <= _attemptsPerEndpoint; attempt++) {
        try {
          final response = await http
              .post(Uri.parse(url), body: {'data': query})
              .timeout(_requestTimeout);

          if (response.statusCode != 200) {
            throw Exception('Overpass API error: ${response.statusCode}');
          }

          final json = jsonDecode(response.body);
          return (json['elements'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        } catch (e) {
          lastError = e;
          log('Overpass request to $url failed (attempt $attempt/$_attemptsPerEndpoint): $e');
        }
      }
    }

    throw Exception('All Overpass endpoints failed. Last error: $lastError');
  }

  static String _polygon(List<LatLng> boundary) =>
      boundary.map((p) => '${p.latitude} ${p.longitude}').join(' ');

  static String _buildQuery(String filter, List<LatLng> boundary) {
    final poly = _polygon(boundary);
    return '''
      [out:json][timeout:300];
      (
        $filter(poly:"$poly");
      );
      out geom;
      ''';
  }

  static Future<List<T>> _fetchAndParse<T>(
    List<LatLng> boundary,
    String filter,
    T Function(Map<String, dynamic>) parser,
  ) async {
    if (boundary.isEmpty) return [];

    final query = _buildQuery(filter, boundary);
    final elements = await _fetchElements(query);

    final result = <T>[];

    for (final e in elements) {
      try {
        result.add(parser(e));
      } catch (err) {
        log('Element parsing failed: $err');
      }
    }

    return result;
  }

  static Future<List<Station>> _fetchStations(
    List<LatLng> boundary,
    String filter,
    StationType type,
  ) async {
    final stations = await _fetchAndParse(
      boundary,
      filter,
      (e) => Station.fromOverpassElement(type, e),
    );

    final seen = <String>{};
    return stations.where((s) => seen.add(s.name)).toList();
  }

  static Future<List<Station>> fetchTrainStations(List<LatLng> boundary) =>
      _fetchStations(
        boundary,
        'nwr["railway"~"^(station|halt)\$"]["station"!="subway"]',
        StationType.trainStation,
      );

  static Future<List<Station>> fetchSubwayStations(List<LatLng> boundary) =>
      _fetchStations(boundary, 'nwr["station"="subway"]', StationType.subway);

  static Future<List<Station>> fetchTramStops(List<LatLng> boundary) =>
      _fetchStations(boundary, 'nwr["railway"="tram_stop"]', StationType.tram);

  static Future<List<Station>> fetchBusStops(List<LatLng> boundary) =>
      _fetchStations(boundary, 'nwr["highway"="bus_stop"]', StationType.bus);

  static Future<List<Station>> fetchFerryStops(List<LatLng> boundary) =>
      _fetchStations(boundary, 'nwr["amenity"="ferry_terminal"]', StationType.ferry);

  static Future<List<MapOverlay>> _fetchOverlays(
    List<LatLng> boundary,
    String filter,
    MapOverlayType type,
  ) {
    return _fetchAndParse(
      boundary,
      filter,
      (e) => MapOverlay.fromOverpassElement(type, e),
    );
  }

  static Future<List<MapOverlay>> fetchBorderLevel(MapOverlayType type, int level, List<LatLng> boundary) =>
      _fetchOverlays(
        boundary,
        'rel["boundary"="administrative"]["admin_level"="$level"]["name"]',
        type,
      );

  static Future<List<MapPOI>> fetchPois(PoiCategory category, List<LatLng> boundary) =>
      _fetchAndParse(
        boundary,
        category.overpassFilter,
        (e) => MapPOI.fromOverpassElement(category, e),
      );
}

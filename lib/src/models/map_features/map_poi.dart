import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'poi_categories.dart';

class MapPOI with ClusterItem {
  final String id;
  final String name;
  final String? nameEn;
  final LatLng center;
  final List<LatLng>? boundary;
  final PoiCategory category;

  MapPOI({
    required this.id,
    required this.name,
    this.nameEn,
    required this.center,
    this.boundary,
    required this.category,
  });

  @override
  LatLng get location => center;

  factory MapPOI.fromOverpassElement(PoiCategory category, Map<String, dynamic> e) {
    final id = e['id'].toString();
    final tags = (e['tags'] as Map?)?.cast<String, String>();
    final name = tags?['name'] ?? 'Unnamed POI';
    final nameEn = tags?['name:en'];

    if (e['type'] == 'node' && e['lat'] != null && e['lon'] != null) {
      return MapPOI(
        id: id,
        name: name,
        nameEn: nameEn,
        center: LatLng(e['lat'], e['lon']),
        category: category,
      );
    }

    if (e['bounds'] != null) {
      final bounds = e['bounds'] as Map<String, dynamic>;
      final minLat = bounds['minlat'];
      final minLon = bounds['minlon'];
      final maxLat = bounds['maxlat'];
      final maxLon = bounds['maxlon'];

      final center = LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);

      final geometry = (e['geometry'] as List?)
          ?.map((p) => LatLng(p['lat'], p['lon']))
          .toList();

      return MapPOI(
        id: id,
        name: name,
        nameEn: nameEn,
        center: center,
        boundary: geometry,
        category: category,
      );
    }

    throw ArgumentError('Invalid element: missing coordinates or bounds for POI $id');
  }

  @override
  String toString() =>
      'MapPOI(name: $name, center: $center, boundaryPoints: ${boundary?.length ?? 0})';
}

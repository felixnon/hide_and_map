import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    hide ClusterManager, Cluster;

import '../../../main.dart';
import '../../util/geo_math.dart';
import '../../util/location_provider.dart';
import '../../util/station_grouper.dart';
import 'map_poi.dart';
import 'map_overlay.dart';
import 'poi_categories.dart';
import 'station.dart';

class FeatureMarkerProvider extends ChangeNotifier {
  final void Function(LatLng point, MarkerId markerId) _onMarkerTap;
  final void Function(MapOverlay overlay) _onOverlayTap;

  final Set<Polygon> _polygons = {};
  final Set<Polygon> _overlayPolygons = {};
  final Set<Circle> _circles = {};

  Set<Polygon> get getPolygons => {..._polygons, ..._overlayPolygons};
  Set<Circle> get getCircles => {..._circles};

  bool _hidingZonesVisible = false;
  double _hidingZoneSize = prefs.hidingZoneSize;
  bool get hidingZonesVisible => _hidingZonesVisible;

  bool dataChanged = false;

  late ClusterManager<Station> _stationClusterManager;
  Set<Marker> _stationMarkers = {};
  Map<String, StationGroup> _hidingZoneGroupByStationId = {};

  final Map<PoiCategory, ClusterManager<MapPOI>> _poiManagers = {};
  final Map<PoiCategory, Set<Marker>> _poiMarkers = {};

  FeatureMarkerProvider(this._onMarkerTap, this._onOverlayTap) {
    init();
  }

  void init() async {
    _stationClusterManager = _createClusterManager<Station>(
      items: [],
      onMarkersUpdated: (markers) {
        _stationMarkers = markers;
        notifyListeners();
      },
      markerBuilder: _getStationMarkerBuilder(),
    );

    for (final cat in kPoiCategories) {
      _poiManagers[cat] = _createClusterManager<MapPOI>(
        items: [],
        onMarkersUpdated: (markers) {
          _poiMarkers[cat] = markers;
          notifyListeners();
        },
        markerBuilder: _getPoiMarkerBuilder(cat),
      );
    }

    prefs.addListener(() {
      if (prefs.hidingZoneSize != _hidingZoneSize) {
        _hidingZoneSize = prefs.hidingZoneSize;
        setHidingZonesVisible(_hidingZonesVisible);
      }
    });
  }

  ClusterManager<T> _createClusterManager<T extends ClusterItem>({
    required List<T> items,
    required void Function(Set<Marker>) onMarkersUpdated,
    required Future<Marker> Function(Cluster<T>) markerBuilder,
  }) {
    return ClusterManager<T>(
      items,
      onMarkersUpdated,
      markerBuilder: markerBuilder,
      levels: const [1, 4.25, 6.5, 8.5, 10.0, 11.0],
      extraPercent: 0.2,
      stopClusteringZoom: 11,
    );
  }

  Future<Marker> Function(Cluster<Station>) _getStationMarkerBuilder() =>
      (cluster) async {
        if (!cluster.isMultiple) {
          _addCircle(cluster.items.first);
          return _buildStationMarker(cluster.items.first);
        }

        final markerId = MarkerId(cluster.getId());
        return Marker(
          markerId: markerId,
          position: cluster.location,
          anchor: const Offset(0.5, 0.5),
          icon: await _getMarkerBitmap(
            60,
            Colors.deepPurple,
            text: cluster.count.toString(),
          ),
          consumeTapEvents: true,
          onTap: () => _onMarkerTap(cluster.location, markerId),
        );
      };

  Future<Marker> Function(Cluster<MapPOI>) _getPoiMarkerBuilder(PoiCategory category) =>
      (cluster) async {
        if (!cluster.isMultiple) {
          _addPolygon(cluster.items.first);
          return _buildPoiMarker(cluster.items.first, icons.poiIcons[category.id]!);
        }

        final markerId = MarkerId(cluster.getId());
        return Marker(
          markerId: markerId,
          position: cluster.location,
          anchor: const Offset(0.5, 0.5),
          icon: await _getMarkerBitmap(60, category.color, text: cluster.count.toString()),
          consumeTapEvents: true,
          onTap: () => _onMarkerTap(cluster.location, markerId),
        );
      };

  Future<Marker> _buildStationMarker(Station station) async {
    String title = station.name;

    if (LocationProvider.lastLocation.latitude != 0.0 &&
        LocationProvider.lastLocation.longitude != 0.0) {
      title +=
          ' (${GeoMath.toDistanceString(GeoMath.distanceInMeters(LocationProvider.lastLocation, station.location))})';
    }

    final markerId = MarkerId('station_${station.id}');
    return Marker(
      markerId: markerId,
      position: station.location,
      icon: _getStationIcon(station.type),
      infoWindow: InfoWindow(title: title, snippet: station.nameEn),
      consumeTapEvents: true,
      onTap: () => _onMarkerTap(station.location, markerId),
    );
  }

  BitmapDescriptor _getStationIcon(StationType type) {
    switch (type) {
      case StationType.trainStation:
        return icons.trainStationIcon;
      case StationType.subway:
        return icons.subwayIcon;
      case StationType.tram:
        return icons.tramIcon;
      case StationType.bus:
        return icons.busIcon;
      case StationType.ferry:
        return icons.ferryIcon;
    }
  }

  Future<Marker> _buildPoiMarker(MapPOI poi, BitmapDescriptor icon) async {
    String title = poi.name;

    if (LocationProvider.lastLocation.latitude != 0.0 &&
        LocationProvider.lastLocation.longitude != 0.0) {
      title +=
          ' (${GeoMath.toDistanceString(GeoMath.distanceInMeters(LocationProvider.lastLocation, poi.center))})';
    }

    final markerId = MarkerId('${poi.category.id}_${poi.id}');
    return Marker(
      markerId: markerId,
      position: poi.center,
      icon: icon,
      infoWindow: InfoWindow(title: title, snippet: poi.nameEn),
      consumeTapEvents: true,
      onTap: () => _onMarkerTap(poi.center, markerId),
    );
  }

  Future<BitmapDescriptor> _getMarkerBitmap(int size, Color color, {String? text}) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    final paint1 = Paint()..color = color;
    final paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.4, paint1);

    if (text != null) {
      final painter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: text,
          style: TextStyle(fontSize: size / 3, color: Colors.white),
        )
        ..layout();

      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ImageByteFormat.png) as ByteData;

    return BitmapDescriptor.bytes(bytes.buffer.asUint8List());
  }

  void _addCircle(Station station) {
    if (!_hidingZonesVisible) return;

    final group = _hidingZoneGroupByStationId[station.id];
    if (group == null) return;

    final circleId = CircleId('zone_${group.id}');
    if (_circles.any((c) => c.circleId == circleId)) return;

    _circles.add(
      Circle(
        circleId: circleId,
        center: group.centroid,
        radius: _hidingZoneSize,
        fillColor: Colors.teal.withAlpha(20),
        strokeColor: Colors.teal.withAlpha(100),
        strokeWidth: 2,
      ),
    );
  }

  void _addPolygon(MapPOI poi) {
    if (poi.boundary == null || poi.boundary!.isEmpty) return;

    final color = poi.category.color;
    _polygons.add(
      Polygon(
        polygonId: PolygonId('${poi.category.id}_${poi.id}'),
        points: poi.boundary!,
        strokeWidth: 2,
        strokeColor: color,
        fillColor: color.withAlpha(102),
      ),
    );
  }

  void setOverlays(MapOverlayType type, List<MapOverlay> overlays) {
    _overlayPolygons.removeWhere((p) => p.polygonId.value.startsWith(type.name));

    for (final overlay in overlays) {
      if (overlay.boundaryPolygons.isEmpty) continue;

      _overlayPolygons.addAll(overlay.toPolygons(_onOverlayTap));
    }

    dataChanged = true;
    notifyListeners();
  }

  void setStations(List<Station> stations) {
    dataChanged = true;
    _circles.clear();
    _hidingZoneGroupByStationId = {
      for (final group in StationGrouper.group(stations))
        for (final s in group.stations) s.id: group,
    };
    _stationClusterManager.setItems(stations);
  }

  void setPOIs(PoiCategory category, List<MapPOI> items) {
    dataChanged = true;
    _poiManagers[category]?.setItems(items);

    if (items.isEmpty) {
      _polygons.removeWhere((p) => p.mapsId.value.startsWith(category.id));
    }
  }

  void setHidingZonesVisible(bool value) {
    _hidingZonesVisible = value;
    dataChanged = true;
    _circles.clear();
    _stationClusterManager.updateMap();
  }

  void setMapId(int mapId) {
    for (final manager in _allManagers) {
      manager.setMapId(mapId);
    }
  }

  void onCameraMove(CameraPosition position) {
    for (final manager in _allManagers) {
      if (manager.items.isNotEmpty) {
        manager.onCameraMove(position);
      }
    }
  }

  void onCameraIdle() {
    _polygons.clear();
    _circles.clear();
    for (final manager in _allManagers) {
      if (manager.items.isNotEmpty) {
        manager.updateMap();
      }
    }
  }

  Set<Marker> get allMarkers => {
    ..._stationMarkers,
    for (final markers in _poiMarkers.values) ...markers,
  };

  List<ClusterManager> get _allManagers => [
    _stationClusterManager,
    ..._poiManagers.values,
  ];

  void resetAll() {
    _polygons.clear();
    _overlayPolygons.clear();
    _circles.clear();
    _stationClusterManager.setItems(<Station>[]);

    for (final manager in _poiManagers.values) {
      manager.setItems(<MapPOI>[]);
    }

    dataChanged = true;
  }
}

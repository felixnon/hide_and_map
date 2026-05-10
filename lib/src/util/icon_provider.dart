import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../main.dart';
import '../models/map_features/poi_categories.dart';

class IconProvider {
  static final IconProvider _instance = IconProvider._internal();
  factory IconProvider() => _instance;
  IconProvider._internal();

  late BitmapDescriptor trainStationIcon;
  late BitmapDescriptor subwayIcon;
  late BitmapDescriptor tramIcon;
  late BitmapDescriptor busIcon;
  late BitmapDescriptor ferryIcon;

  late Map<String, BitmapDescriptor> poiIcons;

  late BitmapDescriptor webLocationIcon;
  late Map<int, BitmapDescriptor> timerIcons;

  late Size _iconSize;

  Future<void> init() async {
    _iconSize = prefs.iconSize;
    await loadIcons();
    prefs.addListener(() {
      if (prefs.iconSize != _iconSize) {
        _iconSize = prefs.iconSize;
        loadIcons();
      }
    });
  }

  Future<void> loadIcons() async {
    trainStationIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: _iconSize),
      'assets/markers/train_station_marker.png',
    );
    subwayIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: _iconSize),
      'assets/markers/subway_station_marker.png',
    );
    tramIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: _iconSize),
      'assets/markers/tram_stop_marker.png',
    );
    busIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: _iconSize),
      'assets/markers/bus_stop_marker.png',
    );
    ferryIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: _iconSize),
      'assets/markers/ferry_stop_marker.png',
    );

    poiIcons = {
      for (final cat in kPoiCategories)
        cat.id: await BitmapDescriptor.asset(
          ImageConfiguration(size: _iconSize),
          cat.markerAsset,
        ),
    };

    webLocationIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: _iconSize),
      'assets/markers/blue_marker.png',
    );

    timerIcons = {
      Colors.blue.toARGB32(): await _loadTimerIcon('blue'),
      Colors.cyan.toARGB32(): await _loadTimerIcon('cyan'),
      Colors.green.toARGB32(): await _loadTimerIcon('green'),
      Colors.yellow.toARGB32(): await _loadTimerIcon('yellow'),
      Colors.orange.toARGB32(): await _loadTimerIcon('orange'),
      Colors.red.toARGB32(): await _loadTimerIcon('red'),
      Colors.pink.toARGB32(): await _loadTimerIcon('pink'),
      Colors.purple.toARGB32(): await _loadTimerIcon('purple'),
      Colors.deepPurple.toARGB32(): await _loadTimerIcon('deep_purple'),
      Colors.indigo.toARGB32(): await _loadTimerIcon('indigo'),
      Colors.grey.toARGB32(): await _loadTimerIcon('grey'),
    };
  }

  Future<BitmapDescriptor> _loadTimerIcon(String colorName) {
    return BitmapDescriptor.asset(
      ImageConfiguration(size: _iconSize + Offset(8, 8)),
      'assets/markers/timer_${colorName}_marker.png',
    );
  }
}

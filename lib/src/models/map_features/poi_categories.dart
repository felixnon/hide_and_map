import 'package:flutter/material.dart';

class PoiCategory {
  final String id;
  final String title;
  final String overpassFilter;
  final IconData panelIcon;
  final Color color;
  final String markerAsset;

  const PoiCategory({
    required this.id,
    required this.title,
    required this.overpassFilter,
    required this.panelIcon,
    required this.color,
    required this.markerAsset,
  });
}

const List<PoiCategory> kPoiCategories = [
  PoiCategory(
    id: 'themePark',
    title: 'Theme Parks',
    overpassFilter: 'nwr["tourism"="theme_park"]',
    panelIcon: Icons.attractions,
    color: Color(0xFFFF6F00),
    markerAsset: 'assets/markers/theme_park_marker.png',
  ),
  PoiCategory(
    id: 'zoo',
    title: 'Zoos',
    overpassFilter: 'nwr["tourism"="zoo"]',
    panelIcon: Icons.pets,
    color: Color(0xFF43A047),
    markerAsset: 'assets/markers/zoo_marker.png',
  ),
  PoiCategory(
    id: 'aquarium',
    title: 'Aquariums',
    overpassFilter: 'nwr["tourism"="aquarium"]',
    panelIcon: Icons.water,
    color: Color(0xFF3949AB),
    markerAsset: 'assets/markers/aquarium_marker.png',
  ),
  PoiCategory(
    id: 'golfCourse',
    title: 'Golf Courses',
    overpassFilter: 'nwr["leisure"="golf_course"]',
    panelIcon: Icons.golf_course,
    color: Color(0xFF7CB342),
    markerAsset: 'assets/markers/golf_marker.png',
  ),
  PoiCategory(
    id: 'museum',
    title: 'Museums',
    overpassFilter: 'nwr["tourism"="museum"]',
    panelIcon: Icons.museum,
    color: Color(0xFF8E24AA),
    markerAsset: 'assets/markers/museum_marker.png',
  ),
  PoiCategory(
    id: 'movieTheater',
    title: 'Movie Theaters',
    overpassFilter: 'nwr["amenity"="cinema"]',
    panelIcon: Icons.movie,
    color: Color(0xFFD81B60),
    markerAsset: 'assets/markers/cinema_marker.png',
  ),
  PoiCategory(
    id: 'hospital',
    title: 'Hospitals',
    overpassFilter: 'nwr["amenity"="hospital"]',
    panelIcon: Icons.emergency,
    color: Color(0xFFC62828),
    markerAsset: 'assets/markers/hospital_marker.png',
  ),
  PoiCategory(
    id: 'library',
    title: 'Libraries',
    overpassFilter: 'nwr["amenity"="library"]',
    panelIcon: Icons.local_library,
    color: Color(0xFFFBC02D),
    markerAsset: 'assets/markers/library_marker.png',
  ),
  PoiCategory(
    id: 'consulate',
    title: 'Consulates',
    overpassFilter:
        'nwr["diplomatic"="consulate"]["consulate"!="honorary_consul"]["consulate"!="honorary_consulate"]',
    panelIcon: Icons.flag,
    color: Color(0xFF0097A7),
    markerAsset: 'assets/markers/consulate_marker.png',
  ),
];

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/map_features/station.dart';
import 'geo_math.dart';

class StationGroup {
  final List<Station> stations;
  final LatLng centroid;

  StationGroup(this.stations, this.centroid);

  String get id => (stations.map((s) => s.id).toList()..sort()).join('_');
}

abstract class StationGrouper {
  static const double _proximityThresholdMeters = 150.0;
  static const double _hubOverrideProximityMeters = 75.0;
  static const double _substringMaxDistanceMeters = 250.0;
  static const int _minSharedSubstringLength = 6;

  static List<StationGroup> group(List<Station> stations) {
    if (stations.isEmpty) return const [];

    final n = stations.length;
    final parent = List<int>.generate(n, (i) => i);

    int find(int x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]];
        x = parent[x];
      }
      return x;
    }

    void union(int a, int b) {
      final ra = find(a);
      final rb = find(b);
      if (ra != rb) parent[ra] = rb;
    }

    final ngrams = [
      for (final s in stations) _nameNgrams(s, _minSharedSubstringLength),
    ];

    bool sharesSubstring(int a, int b) =>
        ngrams[a].isNotEmpty && ngrams[b].any(ngrams[a].contains);

    // Pass 1: substring edges only (cross-kind, within substring max distance).
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        if (stations[i].type == stations[j].type) continue;
        if (GeoMath.distanceInMeters(stations[i].location, stations[j].location) >=
            _substringMaxDistanceMeters) {
          continue;
        }
        if (sharesSubstring(i, j)) union(i, j);
      }
    }

    // Snapshot pass-1 groups; non-singleton ones become "anchored hubs".
    final pass1Members = <int, List<int>>{};
    for (var i = 0; i < n; i++) {
      pass1Members.putIfAbsent(find(i), () => []).add(i);
    }
    final anchored = List<bool>.filled(n, false);
    final pass1Root = List<int>.filled(n, 0);
    for (final entry in pass1Members.entries) {
      if (entry.value.length > 1) {
        for (final i in entry.value) {
          anchored[i] = true;
          pass1Root[i] = entry.key;
        }
      }
    }

    // Pass 2: proximity edges. A proximity edge that would attach to an
    // anchored hub requires the joining station to share a substring with
    // every original hub member, UNLESS the pair is closer than the hub
    // override threshold (essentially "same physical spot"). Two anchored
    // hubs do not merge via proximity.
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final distance = GeoMath.distanceInMeters(
          stations[i].location,
          stations[j].location,
        );
        if (distance >= _proximityThresholdMeters) continue;
        if (find(i) == find(j)) continue;

        final iAnchored = anchored[i];
        final jAnchored = anchored[j];

        if (iAnchored && jAnchored) continue;

        if (distance >= _hubOverrideProximityMeters) {
          if (iAnchored) {
            final hubMembers = pass1Members[pass1Root[i]]!;
            if (!hubMembers.every((h) => sharesSubstring(j, h))) continue;
          } else if (jAnchored) {
            final hubMembers = pass1Members[pass1Root[j]]!;
            if (!hubMembers.every((h) => sharesSubstring(i, h))) continue;
          }
        }

        union(i, j);
      }
    }

    final buckets = <int, List<Station>>{};
    for (var i = 0; i < n; i++) {
      buckets.putIfAbsent(find(i), () => []).add(stations[i]);
    }

    return buckets.values.map((members) {
      var latSum = 0.0, lngSum = 0.0;
      for (final s in members) {
        latSum += s.location.latitude;
        lngSum += s.location.longitude;
      }
      return StationGroup(
        members,
        LatLng(latSum / members.length, lngSum / members.length),
      );
    }).toList();
  }

  static Set<String> _nameNgrams(Station s, int n) {
    final result = <String>{};
    _addNgrams(result, s.name, n);
    final en = s.nameEn;
    if (en != null) _addNgrams(result, en, n);
    return result;
  }

  static void _addNgrams(Set<String> out, String s, int n) {
    final lower = s.toLowerCase();
    if (lower.length < n) return;
    for (var i = 0; i <= lower.length - n; i++) {
      out.add(lower.substring(i, i + n));
    }
  }
}

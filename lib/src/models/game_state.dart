import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:hide_and_map/src/models/shape/shape_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'play_area/play_area.dart';
import 'shape/shape.dart';

class GameState {
  final PlayArea? playArea;
  final List<Shape> shapes;

  GameState({this.playArea, List<Shape>? shapes}) : shapes = shapes ?? [];

  GameState copyWith({PlayArea? playArea, List<Shape>? shapes}) {
    return GameState(playArea: playArea ?? this.playArea, shapes: shapes ?? this.shapes);
  }

  Map<String, dynamic> _toJson() => {
    'pA': playArea?.toJson(),
    'sh': shapes.map((s) => s.toJson()).toList(),
  };

  /// Standard base64-encoded, gzipped JSON. Used for local storage.
  String encodeGameState() {
    final jsonStr = jsonEncode(_toJson());
    final compressed = GZipEncoder().encode(utf8.encode(jsonStr));
    return base64Encode(compressed);
  }

  /// URL-safe base64 (no `=` padding) of the gzipped JSON. Use for share URLs
  /// and QR codes — the result needs no percent-encoding when placed in a URL.
  String encodeGameStateUrlSafe() {
    final jsonStr = jsonEncode(_toJson());
    final compressed = GZipEncoder().encode(utf8.encode(jsonStr));
    return base64UrlEncode(compressed).replaceAll('=', '');
  }

  static Future<void> saveGameState(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = state.encodeGameState();
    await prefs.setString('game_state', encoded);
  }

  static GameState _fromJson(Map<String, dynamic> json) => GameState(
    playArea: json['pA'] != null ? PlayArea.fromJson(json['pA']) : null,
    shapes: (json['sh'] as List).map((s) => ShapeFactory.fromJson(s)).toList(),
  );

  /// Accepts both standard base64 and URL-safe base64 (with or without
  /// `=` padding). Returns an empty [GameState] if the input is invalid.
  static GameState decodeGameState(String stored) {
    try {
      // Normalize URL-safe alphabet to standard, then re-add padding.
      String normalized = stored.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final compressed = base64Decode(normalized);
      final decompressed = GZipDecoder().decodeBytes(compressed);
      final data = jsonDecode(utf8.decode(decompressed)) as Map<String, dynamic>;
      return _fromJson(data);
    } catch (_) {
      return GameState();
    }
  }

  static Future<GameState> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('game_state');
    if (encoded == null) return GameState();
    return decodeGameState(encoded);
  }

  static Future<void> clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('game_state');
  }
}

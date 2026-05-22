/// Helpers for building and parsing the "share game state" URL.
///
/// The URL embeds a URL-safe base64 (gzipped JSON) game state in the `d`
/// query parameter and may optionally carry the sender's hiding-zone size
/// (in meters) in the `hz` parameter. Anyone opening the URL in a browser
/// will land on the web app, which detects the parameters and prompts to
/// import.
class ShareUrl {
  /// Base URL where the web build is hosted. Update this for forks.
  static const String baseUrl = 'https://felixnon.github.io/hide_and_map/';

  /// Query parameter name that carries the encoded game state.
  static const String paramData = 'd';

  /// Query parameter name that carries the hiding-zone size (in meters).
  static const String paramHidingZone = 'hz';

  /// Build a share URL for the given URL-safe encoded game state. Pass
  /// [hidingZoneSize] (in meters) to also include the sender's hiding-zone
  /// preference; the recipient will be asked to adopt it as part of the
  /// import confirmation.
  static String build(String urlSafeCode, {double? hidingZoneSize}) {
    final params = StringBuffer('$paramData=$urlSafeCode');
    if (hidingZoneSize != null) {
      params.write('&$paramHidingZone=${hidingZoneSize.round()}');
    }
    return '$baseUrl?$params';
  }

  /// Parse [input] as either a share URL or a raw encoded code.
  ///
  /// Returns `null` if [input] is empty or looks like a URL but has no
  /// `d=` parameter (a URL with only `hz=` is ignored — there is nothing
  /// to import without a game state).
  static SharePayload? extractPayload(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // No URL markers → treat the whole string as a raw code.
    if (!trimmed.contains('?') && !trimmed.contains('://')) {
      return SharePayload(code: trimmed);
    }

    Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return null;
    }

    final code = uri.queryParameters[paramData];
    if (code == null || code.isEmpty) return null;

    final hzStr = uri.queryParameters[paramHidingZone];
    final hz = hzStr == null ? null : double.tryParse(hzStr);

    return SharePayload(code: code, hidingZoneSize: hz);
  }
}

/// Parsed contents of a share URL or pasted code.
class SharePayload {
  /// URL-safe base64 game state code.
  final String code;

  /// Optional hiding-zone size (meters) from the sender's preferences.
  final double? hidingZoneSize;

  const SharePayload({required this.code, this.hidingZoneSize});
}

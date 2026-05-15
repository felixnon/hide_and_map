/// Helpers for building and parsing the "share game state" URL.
///
/// The URL embeds a URL-safe base64 (gzipped JSON) game state in the `d`
/// query parameter. Anyone opening the URL in a browser will land on the
/// web app, which detects the parameter and prompts to import.
class ShareUrl {
  /// Base URL where the web build is hosted. Update this for forks.
  static const String baseUrl = 'https://felixnon.github.io/hide_and_map/';

  /// Query parameter name that carries the encoded game state.
  static const String paramName = 'd';

  /// Build a share URL for the given URL-safe encoded game state.
  static String build(String urlSafeCode) {
    return '$baseUrl?$paramName=$urlSafeCode';
  }

  /// If [input] looks like a share URL, return the embedded game state code.
  /// Returns `null` for plain codes or unrecognized URLs.
  static String? extractCode(String input) {
    final trimmed = input.trim();
    // Quick reject: codes don't contain `://` or `?`.
    if (!trimmed.contains('?') && !trimmed.contains('://')) return null;
    Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return null;
    }
    final code = uri.queryParameters[paramName];
    if (code == null || code.isEmpty) return null;
    return code;
  }
}

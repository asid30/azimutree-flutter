// Service to convert Google Drive file links into thumbnail URLs usable
// in image templates (such as Excel templates requiring direct image links).
import 'package:http/http.dart' as http;

class GDriveThumbnailService {
  // Simple in-memory cache mapping Drive file id -> resolved URL
  static final Map<String, String> _cache = <String, String>{};

  /// Convert a Google Drive URL to a thumbnail URL with given size (width).
  ///
  /// If the input URL doesn't look like a Google Drive file link, the
  /// original URL is returned unchanged.
  ///
  /// Example:
  /// Before: https://drive.google.com/file/d/1LvRGf.../view?usp=drive_link
  /// After : https://drive.google.com/thumbnail?id=1LvRGf...&sz=w300
  static String toThumbnailUrl(String url, {int size = 300}) {
    final id = _extractFileId(url);
    if (id == null || id.isEmpty) return url;
    // If we previously resolved a working URL for this id, return it.
    if (_cache.containsKey(id)) return _cache[id]!;

    // Use the Google Drive thumbnail endpoint which returns a resized
    // image. This is fast and suitable for small previews and is used
    // as the immediate (synchronous) URL returned to image widgets.
    // Example: https://drive.google.com/thumbnail?id=<id>&sz=w300
    final thumb = 'https://drive.google.com/thumbnail?id=$id&sz=w$size';
    return thumb;
  }

  /// Return true when the provided URL looks like a Google Drive file link.
  static bool isGDriveUrl(String url) => _extractFileId(url) != null;

  /// Return a list of candidate direct URLs for the given Drive link.
  /// Useful as fallbacks: some Drive hosts accept different URL forms.
  static List<String> candidateUrls(String url, {int size = 300}) {
    final id = _extractFileId(url);
    if (id == null || id.isEmpty) return [url];

    // 1) drive.usercontent download/view (preferred)
    final usercontent =
        'https://drive.usercontent.google.com/download?id=$id&export=view&authuser=0';

    // 2) lh3 googleusercontent direct thumbnail (observed working in browser)
    final lh3 = 'https://lh3.googleusercontent.com/d/$id=w$size?authuser=0';

    // 3) Thumbnail endpoint (fallback)
    final thumb = 'https://drive.google.com/thumbnail?id=$id&sz=w$size';

    // 4) UC export view (embed-like direct view)
    final view = 'https://drive.google.com/uc?export=view&id=$id';

    // 5) UC direct download
    final download = 'https://drive.google.com/uc?export=download&id=$id';

    return [usercontent, lh3, thumb, view, download];
  }

  /// Try candidate Drive URLs (thumbnail, view, download) and return the
  /// first one that responds with HTTP 200 and an image-like content-type.
  ///
  /// If none of the candidates succeed, returns the original input URL.
  static Future<String> findWorkingUrl(
    String url, {
    int size = 300,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final candidates = candidateUrls(url, size: size);

    final id = _extractFileId(url);
    if (id != null && _cache.containsKey(id)) return _cache[id]!;

    for (final c in candidates) {
      try {
        final uri = Uri.parse(c);
        final resp = await http.head(uri).timeout(timeout);
        if (resp.statusCode == 200) {
          final ct = resp.headers['content-type'] ?? '';
          if (ct.startsWith('image/') || c.contains('thumbnail')) {
            // store into cache
            if (id != null) _cache[id] = c;
            return c;
          }
        }
        // Some hosts don't respond to HEAD; try GET as fallback but don't
        // download the full body (we still issue a GET and cancel on timeout).
        final respGet = await http.get(uri).timeout(timeout);
        if (respGet.statusCode == 200) {
          final ct = respGet.headers['content-type'] ?? '';
          if (ct.startsWith('image/') || c.contains('thumbnail')) {
            if (id != null) _cache[id] = c;
            return c;
          }
        }
      } catch (_) {
        // ignore and try next candidate
      }
    }

    return url;
  }

  /// Attempts to extract a Google Drive file id from common share link
  /// formats. Returns null when no file id can be found.
  static String? _extractFileId(String url) {
    if (url.isEmpty) return null;

    // Common pattern: /file/d/<id>/...
    final fileIdFromPath = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
    final m1 = fileIdFromPath.firstMatch(url);
    if (m1 != null) return m1.group(1);

    // Pattern: ?id=<id> or &id=<id>
    final idQuery = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
    final m2 = idQuery.firstMatch(url);
    if (m2 != null) return m2.group(1);

    // Pattern: /uc?id=<id>
    final ucPattern = RegExp(r'uc\?id=([a-zA-Z0-9_-]+)');
    final m3 = ucPattern.firstMatch(url);
    if (m3 != null) return m3.group(1);

    // Some sharing links contain /open?id=<id>
    final openPattern = RegExp(r'/open\?id=([a-zA-Z0-9_-]+)');
    final m4 = openPattern.firstMatch(url);
    if (m4 != null) return m4.group(1);

    return null;
  }
}

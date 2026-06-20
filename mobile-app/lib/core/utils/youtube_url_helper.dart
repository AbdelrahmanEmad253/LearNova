/// Utility to detect and extract YouTube video IDs from URLs.
class YoutubeUrlHelper {
  const YoutubeUrlHelper._();

  /// Returns true if [url] is a YouTube video link.
  static bool isYoutubeUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.contains('youtube-nocookie.com');
  }

  /// Extracts the video ID from a YouTube URL.
  /// Returns null if not a valid YouTube URL.
  static String? extractVideoId(String url) {
    // Handles:
    // - https://www.youtube.com/watch?v=VIDEO_ID
    // - https://youtu.be/VIDEO_ID
    // - https://www.youtube.com/embed/VIDEO_ID
    // - https://www.youtube-nocookie.com/embed/VIDEO_ID
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // youtube.com/watch?v=...
    if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }

    // youtu.be/VIDEO_ID
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    // youtube.com/embed/VIDEO_ID or youtube-nocookie.com/embed/VIDEO_ID
    if ((uri.host.contains('youtube.com') || uri.host.contains('youtube-nocookie.com')) &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments[0] == 'embed') {
      return uri.pathSegments[1];
    }

    return null;
  }
}

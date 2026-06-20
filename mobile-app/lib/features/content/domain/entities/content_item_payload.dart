class ContentItemPayload {
  final String id;
  final String title;
  final String contentType;
  final String meta;

  /// The actual media URL (Supabase Storage URL, YouTube link, etc.).
  /// Null when content is text-only or the URL hasn't been resolved yet.
  final String? mediaUrl;

  const ContentItemPayload({
    required this.id,
    required this.title,
    required this.contentType,
    required this.meta,
    this.mediaUrl,
  });
}

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// Service that fetches a web page and extracts readable text content.
///
/// The extracted text is returned as a list of pages, where each page is
/// a list of paragraph strings – compatible with [DocumentReaderController].
class ArticleExtractorService {
  const ArticleExtractorService._();

  /// Maximum number of paragraph strings per "page".
  static const int _paragraphsPerPage = 3;

  /// Minimum characters a paragraph must have to be kept.
  static const int _minParagraphLength = 40;

  /// Fetches the HTML at [url] and extracts text paragraphs grouped into pages.
  ///
  /// Returns `null` if the request fails, or the page contains too little text.
  static Future<List<List<String>>?> extract(String url) async {
    try {
      final http.Response response = await http
          .get(Uri.parse(url), headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          })
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return null;
      }

      final dom.Document document = html_parser.parse(response.body);

      // Try to find text in priority order: <article>, <main>, then <body>.
      final List<String> paragraphs = _extractParagraphs(document);

      if (paragraphs.length < 2) {
        return null; // Not enough text to render in reader mode.
      }

      return _groupIntoPages(paragraphs);
    } catch (_) {
      return null;
    }
  }

  /// Extracts the page title from the HTML document.
  static Future<String?> extractTitle(String url) async {
    try {
      final http.Response response = await http
          .get(Uri.parse(url), headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          })
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;
      final dom.Document document = html_parser.parse(response.body);
      final dom.Element? titleEl = document.querySelector('title');
      final String? ogTitle = document
          .querySelector('meta[property="og:title"]')
          ?.attributes['content'];
      return ogTitle ?? titleEl?.text.trim();
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static List<String> _extractParagraphs(dom.Document document) {
    // Remove noise elements.
    for (final tag in ['script', 'style', 'nav', 'footer', 'header', 'aside',
        'noscript', 'iframe', 'form', 'button', 'svg']) {
      document.querySelectorAll(tag).forEach((el) => el.remove());
    }

    // Priority containers.
    final List<String> candidates = <String>[];

    for (final selector in ['article', 'main', '[role="main"]', '.post-content',
        '.article-body', '.entry-content', '#content', 'body']) {
      final dom.Element? container = document.querySelector(selector);
      if (container == null) continue;

      final List<String> found = _textFromContainer(container);
      if (found.length >= 2) {
        return found;
      }
      candidates.addAll(found);
    }

    return candidates.length >= 2 ? candidates : <String>[];
  }

  static List<String> _textFromContainer(dom.Element container) {
    final List<String> paragraphs = <String>[];

    for (final dom.Element el in container.querySelectorAll('h1, h2, h3, h4, h5, h6, p, li, blockquote, pre, td, th, figcaption, dt, dd')) {
      String text = el.text.trim();
      // Clean up whitespace.
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (text.length < _minParagraphLength) continue;

      // Bold headings.
      final String tagName = el.localName ?? '';
      if (tagName.startsWith('h')) {
        text = '**$text**';
      }

      paragraphs.add(text);
    }

    return paragraphs;
  }

  static List<List<String>> _groupIntoPages(List<String> paragraphs) {
    final List<List<String>> pages = <List<String>>[];

    for (int i = 0; i < paragraphs.length; i += _paragraphsPerPage) {
      final int end = (i + _paragraphsPerPage > paragraphs.length)
          ? paragraphs.length
          : i + _paragraphsPerPage;
      pages.add(paragraphs.sublist(i, end));
    }

    return pages;
  }
}

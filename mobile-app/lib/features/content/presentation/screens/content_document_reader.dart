import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/features/content/domain/entities/content_item_payload.dart';
import 'package:learnova/features/content/domain/services/article_extractor_service.dart';
import 'package:learnova/features/content/presentation/controllers/document_reader_controller.dart';
import 'package:learnova/features/home/presentation/providers/home_providers.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DocumentReaderPlaceholderScreen extends ConsumerStatefulWidget {
  final ContentItemPayload item;
  final List<List<String>>? pages;
  final int initialPage;
  final List<ContentItemPayload>? moduleItems;
  final int? moduleIndex;
  final String? moduleId;

  const DocumentReaderPlaceholderScreen({
    super.key,
    required this.item,
    this.pages,
    this.initialPage = 3,
    this.moduleItems,
    this.moduleIndex,
    this.moduleId,
  });

  @override
  ConsumerState<DocumentReaderPlaceholderScreen> createState() =>
      _DocumentReaderPlaceholderScreenState();
}

class _DocumentReaderPlaceholderScreenState
    extends ConsumerState<DocumentReaderPlaceholderScreen> {
  DocumentReaderController? _controller;
  WebViewController? _docWebViewController;
  bool _webViewLoading = true;

  /// true = reader mode (extracted text), false = web view mode.
  bool _readerMode = true;

  /// Whether article extraction is in progress.
  bool _extracting = false;

  /// Extracted pages from the article (null if extraction failed).
  List<List<String>>? _extractedPages;

  static const List<String> _mockBookmarkTitles = <String>[
    'Introduction',
    'First Steps',
    'Creating a ggplot',
    'A Graphing template',
    'Data Wrangling',
    'Visualization Basics',
    'Model Building',
    'Practical Notes',
  ];

  bool get _hasWebUrl {
    final String? url = _resolvedMediaUrl();
    return url != null && url.trim().isNotEmpty && url.startsWith('http');
  }

  String? _resolvedMediaUrl() {
    final String directUrl = widget.item.mediaUrl?.trim() ?? '';
    if (directUrl.isNotEmpty) {
      return directUrl;
    }

    final List<ContentItemPayload>? moduleItems = widget.moduleItems;
    if (moduleItems != null) {
      for (final item in moduleItems) {
        if (item.id == widget.item.id) {
          final String candidate = item.mediaUrl?.trim() ?? '';
          if (candidate.isNotEmpty) {
            return candidate;
          }
        }
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );

    // If explicit pages were passed, use them directly.
    if (widget.pages != null && widget.pages!.isNotEmpty) {
      _controller = DocumentReaderController(
        pages: widget.pages!,
        initialPageIndex: widget.initialPage - 1,
      );
    }

    if (_hasWebUrl) {
      final String mediaUrl = _resolvedMediaUrl()!;

      // Initialize WebView (used as fallback or toggle target).
      _docWebViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _webViewLoading = false);
          },
        ))
        ..loadRequest(Uri.parse(mediaUrl));

      // Attempt article extraction.
      if (_controller == null) {
        _extractArticle(mediaUrl);
      }
    }
  }

  Future<void> _extractArticle(String url) async {
    setState(() => _extracting = true);

    final List<List<String>>? pages = await ArticleExtractorService.extract(url);

    if (!mounted) return;

    setState(() {
      _extracting = false;
      _extractedPages = pages;

      if (pages != null && pages.isNotEmpty) {
        _controller = DocumentReaderController(
          pages: pages,
          initialPageIndex: 0,
        );
        _readerMode = true;
      } else {
        // Extraction failed – default to WebView.
        _readerMode = false;
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  List<_BookmarkEntry> _buildBookmarks({required int totalPages}) {
    return List<_BookmarkEntry>.generate(totalPages, (index) {
      final String title = index < _mockBookmarkTitles.length
          ? _mockBookmarkTitles[index]
          : 'Section ${index + 1}';
      return _BookmarkEntry(
          title: '${index + 1}- $title', pageNumber: index + 1);
    });
  }

  void _showBookmarksSheet(double sx, double sy, double ss) {
    final DocumentReaderController? controller = _controller;
    if (controller == null) {
      return;
    }

    final List<_BookmarkEntry> bookmarks =
        _buildBookmarks(totalPages: controller.totalPages);

    final colors = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ColorManager.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        return Container(
          height: 420 * sy,
          decoration: BoxDecoration(
            color: colors.isDark ? ColorManager.sheetSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: colors.isDark ? null : Border.all(color: colors.borderWeak),
          ),
          child: Column(
            children: [
              SizedBox(height: 28 * sy),
              Text(
                'Title Bookmarks',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 40 * ss,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 22 * sy),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final _BookmarkEntry entry = bookmarks[index];
                    final bool isCurrent =
                        entry.pageNumber == controller.currentPageNumber;

                    return InkWell(
                      onTap: () {
                        controller.jumpToPage(entry.pageNumber);
                        AppRouter.pop(sheetContext);
                      },
                      child: Container(
                        height: 52 * sy,
                        decoration: isCurrent
                            ? BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.15),
                              )
                            : null,
                        padding: EdgeInsets.symmetric(horizontal: 14 * sx),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.title,
                                style: TextStyle(
                                  color: isCurrent
                                      ? colors.primary
                                      : colors.textSecondary,
                                  fontSize: 29 * ss,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.pageNumber}',
                              style: TextStyle(
                                color: isCurrent
                                    ? colors.primary
                                    : colors.textSecondary,
                                fontSize: 30 * ss,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onFinishPressed() {
    if (widget.moduleId != null) {
      ref.read(moduleProgressProvider.notifier).markItemCompleted(
            moduleId: widget.moduleId!,
            itemId: widget.item.id,
          );
    }
    AppRouter.pop(context);
  }

  void _toggleMode() {
    setState(() {
      _readerMode = !_readerMode;
    });
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // If extracting, show a loading screen.
    if (_extracting) {
      return _buildLoadingState(context);
    }

    // Reader mode with extracted or provided pages.
    if (_readerMode && _controller != null) {
      return _buildReaderLayout(context);
    }

    // WebView mode.
    if (_docWebViewController != null) {
      return _buildWebViewLayout(context);
    }

    // No content at all.
    return _buildEmptyState(context);
  }

  // --------------------------------------------------------------------------
  // Loading state (during extraction)
  // --------------------------------------------------------------------------

  Widget _buildLoadingState(BuildContext context) {
    final colors = AppColors.of(context);
    final Size size = MediaQuery.of(context).size;
    final double sx = size.width / 412;
    final double sy = size.height / 917;
    final double ss = math.min(sx, sy);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: -11.891 * sx,
              bottom: -11.98 * sy,
              width: 444.862 * sx,
              height: 319.383 * sy,
              child: IgnorePointer(
                child: SvgPicture.asset(
                  AppAssets.contentWaveBottom,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: colors.primary,
                  ),
                  SizedBox(height: 24 * sy),
                  Text(
                    'Extracting article text…',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18 * ss,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8 * sy),
                  Text(
                    'This may take a few seconds',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14 * ss,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WebView layout (with optional toggle to reader)
  // --------------------------------------------------------------------------

  Widget _buildWebViewLayout(BuildContext context) {
    final colors = AppColors.of(context);
    final Size size = MediaQuery.of(context).size;
    final double sx = size.width / 412;
    final double sy = size.height / 917;
    final double ss = math.min(sx, sy);

    final bool canSwitchToReader =
        _extractedPages != null && _extractedPages!.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: -11.891 * sx,
              bottom: -11.98 * sy,
              width: 444.862 * sx,
              height: 319.383 * sy,
              child: IgnorePointer(
                child: SvgPicture.asset(
                  AppAssets.contentWaveBottom,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            // Back button.
            Positioned(
              left: 24 * sx,
              top: 8 * sy,
              child: InkWell(
                onTap: () => AppRouter.pop(context),
                borderRadius: BorderRadius.circular(20 * ss),
                child: SizedBox(
                  width: 40 * ss,
                  height: 40 * ss,
                  child: Icon(
                    Icons.arrow_back,
                    color: colors.textPrimary,
                    size: 30 * ss,
                  ),
                ),
              ),
            ),
            // Toggle button (switch to reader mode).
            if (canSwitchToReader)
              Positioned(
                right: 24 * sx,
                top: 8 * sy,
                child: InkWell(
                  onTap: _toggleMode,
                  borderRadius: BorderRadius.circular(12 * ss),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * ss,
                      vertical: 8 * ss,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12 * ss),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          color: ColorManager.buttonDark,
                          size: 18 * ss,
                        ),
                        SizedBox(width: 6 * ss),
                        Text(
                          'Reader',
                          style: TextStyle(
                            color: ColorManager.buttonDark,
                            fontSize: 13 * ss,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // WebView content.
            Positioned(
              left: 24 * sx,
              right: 24 * sx,
              top: 60 * sy,
              bottom: 90 * sy,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18 * ss),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _docWebViewController != null
                          ? WebViewWidget(controller: _docWebViewController!)
                          : const SizedBox.shrink(),
                    ),
                    if (_webViewLoading)
                      Positioned.fill(
                        child: Container(
                          color: colors.background.withValues(alpha: 0.65),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Finish button.
            Positioned(
              left: 26 * sx,
              right: 26 * sx,
              bottom: 24 * sy,
              child: SizedBox(
                height: 56 * sy,
                child: FilledButton(
                  onPressed: _onFinishPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: ColorManager.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * ss),
                    ),
                  ),
                  child: Text(
                    'Finish',
                    style: TextStyle(
                      color: ColorManager.white,
                      fontSize: 30 * ss,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Reader layout (extracted text with page navigation)
  // --------------------------------------------------------------------------

  Widget _buildReaderLayout(BuildContext context) {
    final colors = AppColors.of(context);
    final DocumentReaderController controller = _controller!;
    final Size size = MediaQuery.of(context).size;
    final double sx = size.width / 412;
    final double sy = size.height / 917;
    final double ss = math.min(sx, sy);

    final bool canSwitchToWebView = _docWebViewController != null;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final bool isLastPage = controller.isLastPage;

            return Stack(
              children: [
                Positioned(
                  left: -11.891 * sx,
                  bottom: -11.98 * sy,
                  width: 444.862 * sx,
                  height: 319.383 * sy,
                  child: IgnorePointer(
                    child: SvgPicture.asset(
                      AppAssets.contentWaveBottom,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 220 * sy,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ColorManager.transparent,
                            colors.background.withValues(alpha: 0.55),
                            colors.background,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Back button.
                Positioned(
                  left: 24 * sx,
                  top: 8 * sy,
                  child: InkWell(
                    onTap: () => AppRouter.pop(context),
                    borderRadius: BorderRadius.circular(20 * ss),
                    child: SizedBox(
                      width: 40 * ss,
                      height: 40 * ss,
                      child: Icon(
                        Icons.arrow_back,
                        color: colors.textPrimary,
                        size: 30 * ss,
                      ),
                    ),
                  ),
                ),
                // Toggle to WebView button.
                if (canSwitchToWebView)
                  Positioned(
                    right: 24 * sx,
                    top: 8 * sy,
                    child: InkWell(
                      onTap: _toggleMode,
                      borderRadius: BorderRadius.circular(12 * ss),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * ss,
                          vertical: 8 * ss,
                        ),
                        decoration: BoxDecoration(
                          color: colors.isDark ? ColorManager.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12 * ss),
                          border: Border.all(
                            color: colors.borderWeak,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.language_rounded,
                              color: colors.textPrimary,
                              size: 18 * ss,
                            ),
                            SizedBox(width: 6 * ss),
                            Text(
                              'Web View',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13 * ss,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Document text content.
                Positioned(
                  left: 24 * sx,
                  right: 24 * sx,
                  top: 92 * sy,
                  bottom: 210 * sy,
                  child: SingleChildScrollView(
                    child: _DocumentPageBody(
                      paragraphs: controller.currentParagraphs,
                      fontScale: ss,
                    ),
                  ),
                ),
                // Bookmarks button.
                Positioned(
                  left: 24 * sx,
                  bottom: 120 * sy,
                  child: InkWell(
                    onTap: () => _showBookmarksSheet(sx, sy, ss),
                    borderRadius: BorderRadius.circular(10 * ss),
                    child: SizedBox(
                      width: 32 * ss,
                      height: 32 * ss,
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: colors.textPrimary,
                        size: 28 * ss,
                      ),
                    ),
                  ),
                ),
                // Page navigator pill.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 106 * sy,
                  child: Center(
                    child: _PageNavigatorPill(
                      currentPage: controller.currentPageNumber,
                      totalPages: controller.totalPages,
                      canGoPrevious: controller.canGoPrevious,
                      canGoNext: controller.canGoNext,
                      onPrevious: controller.goPrevious,
                      onNext: controller.goNext,
                      fontScale: ss,
                    ),
                  ),
                ),
                // Finish button (shown on last page).
                if (isLastPage)
                  Positioned(
                    left: 26 * sx,
                    right: 26 * sx,
                    bottom: 24 * sy,
                    child: SizedBox(
                      height: 56 * sy,
                      child: FilledButton(
                        onPressed: _onFinishPressed,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: ColorManager.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10 * ss),
                          ),
                        ),
                        child: Text(
                          'Finish',
                          style: TextStyle(
                            color: ColorManager.white,
                            fontSize: 30 * ss,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Empty state
  // --------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    final colors = AppColors.of(context);
    final Size size = MediaQuery.of(context).size;
    final double sx = size.width / 412;
    final double sy = size.height / 917;
    final double ss = math.min(sx, sy);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: SvgPicture.asset(
                  AppAssets.contentWaveBottom,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32 * sx),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: colors.textPrimary,
                      size: 72 * ss,
                    ),
                    SizedBox(height: 18 * sy),
                    Text(
                      'No document URL was found in Supabase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18 * ss,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10 * sy),
                    Text(
                      'This lesson needs a valid text_url_read value or an explicit page list.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13 * ss,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 24 * sy),
                    SizedBox(
                      width: 180 * sx,
                      height: 52 * sy,
                      child: FilledButton(
                        onPressed: () => AppRouter.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: ColorManager.white,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkEntry {
  final String title;
  final int pageNumber;

  const _BookmarkEntry({required this.title, required this.pageNumber});
}

class _DocumentPageBody extends StatelessWidget {
  final List<String> paragraphs;
  final double fontScale;

  const _DocumentPageBody({required this.paragraphs, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < paragraphs.length; i++) ...[
          _ParagraphWithBoldMarkup(text: paragraphs[i], fontScale: fontScale),
          if (i != paragraphs.length - 1) SizedBox(height: 24 * fontScale),
        ],
      ],
    );
  }
}

class _ParagraphWithBoldMarkup extends StatelessWidget {
  final String text;
  final double fontScale;

  const _ParagraphWithBoldMarkup({required this.text, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final TextStyle baseStyle = TextStyle(
      color: colors.textPrimary,
      fontSize: 16 * fontScale,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w300,
      height: 1.45,
    );
    final TextStyle boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w600);

    return RichText(
        text: TextSpan(children: _parseBoldMarkup(baseStyle, boldStyle)));
  }

  List<InlineSpan> _parseBoldMarkup(TextStyle base, TextStyle bold) {
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    final List<InlineSpan> spans = <InlineSpan>[];

    int cursor = 0;
    for (final Match match in boldPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, match.start),
            style: base,
          ),
        );
      }

      final String boldText = match.group(1) ?? '';
      if (boldText.isNotEmpty) {
        spans.add(TextSpan(text: boldText, style: bold));
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: base));
    }

    return spans;
  }
}

class _PageNavigatorPill extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final double fontScale;

  const _PageNavigatorPill({
    required this.currentPage,
    required this.totalPages,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 18 * fontScale, vertical: 12 * fontScale),
      decoration: BoxDecoration(
        color: colors.isDark ? ColorManager.overlayScrim : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(32 * fontScale),
        border: Border.all(
          color: colors.borderWeak,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PagerArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: canGoPrevious ? onPrevious : null,
            iconSize: 28 * fontScale,
          ),
          SizedBox(width: 8 * fontScale),
          Text(
            '$currentPage',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 30 * fontScale,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          SizedBox(width: 8 * fontScale),
          Text(
            '/',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 34 * fontScale,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          SizedBox(width: 8 * fontScale),
          Text(
            '$totalPages',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 30 * fontScale,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          SizedBox(width: 8 * fontScale),
          _PagerArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: canGoNext ? onNext : null,
            iconSize: 28 * fontScale,
          ),
        ],
      ),
    );
  }
}

class _PagerArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;

  const _PagerArrowButton({
    required this.icon,
    required this.onTap,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkResponse(
      onTap: onTap,
      radius: iconSize,
      child: Icon(
        icon,
        color: onTap == null
            ? colors.textSecondary.withValues(alpha: 0.3)
            : colors.textPrimary,
        size: iconSize,
      ),
    );
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';


/// A wrapper that renders its [child] once, captures it as a bitmap,
/// and then displays the cached raster image on all subsequent frames.
///
/// This eliminates expensive CustomPaint / ClipPath / SVG rasterization
/// during scrolling. The cache is invalidated when [cacheKey] changes
/// (e.g. when the avatar asset path changes).
class CachedPanel extends StatefulWidget {
  const CachedPanel({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    this.cacheKey = '',
  });

  final Widget child;
  final double width;
  final double height;

  /// When this changes, the cached image is invalidated and re-captured.
  final String cacheKey;

  @override
  State<CachedPanel> createState() => _CachedPanelState();
}

class _CachedPanelState extends State<CachedPanel> {
  final GlobalKey _boundaryKey = GlobalKey();
  ui.Image? _cachedImage;
  String _lastCacheKey = '';
  bool _capturing = false;

  @override
  void didUpdateWidget(covariant CachedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      // Avatar changed — invalidate cache
      _cachedImage?.dispose();
      _cachedImage = null;
      _lastCacheKey = '';
      _scheduleCapture();
    }
  }

  @override
  void initState() {
    super.initState();
    _scheduleCapture();
  }

  void _scheduleCapture() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _captureImage();
    });
  }

  Future<void> _captureImage() async {
    if (_capturing || !mounted) return;
    _capturing = true;

    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize) {
        _capturing = false;
        return;
      }

      final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      if (mounted) {
        setState(() {
          _cachedImage?.dispose();
          _cachedImage = image;
          _lastCacheKey = widget.cacheKey;
        });
      } else {
        image.dispose();
      }
    } catch (_) {
      // Silently fail — will show live widget instead
    } finally {
      _capturing = false;
    }
  }

  @override
  void dispose() {
    _cachedImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show cached bitmap if available and cache key matches
    if (_cachedImage != null && _lastCacheKey == widget.cacheKey) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: RawImage(
          image: _cachedImage,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.low,
        ),
      );
    }

    // First frame: render live, then capture
    return RepaintBoundary(
      key: _boundaryKey,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.child,
      ),
    );
  }
}

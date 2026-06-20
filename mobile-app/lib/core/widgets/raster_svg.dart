import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A widget that renders an SVG asset once into a raster image (PNG texture),
/// then displays the cached bitmap on all subsequent frames.
///
/// This eliminates expensive SVG vector-path rasterization during scrolling.
/// The cache is per-asset and per-size, so the same avatar at the same size
/// will only be rasterized once across the entire app.
class RasterSvg extends StatefulWidget {
  const RasterSvg({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  final String assetPath;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  State<RasterSvg> createState() => _RasterSvgState();

  /// Global cache shared across all instances.
  static final Map<String, ui.Image> _cache = {};

  static String _cacheKey(String asset, double w, double h) =>
      '$asset@${w.toInt()}x${h.toInt()}';
}

class _RasterSvgState extends State<RasterSvg> {
  ui.Image? _image;
  bool _loading = false;
  bool _hasError = false;

  String get _key =>
      RasterSvg._cacheKey(widget.assetPath, widget.width, widget.height);

  bool get _isPng => 
      widget.assetPath.toLowerCase().endsWith('.png') ||
      widget.assetPath.toLowerCase().endsWith('.jpg');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPng) {
      _loadImage();
    }
  }

  @override
  void didUpdateWidget(covariant RasterSvg old) {
    super.didUpdateWidget(old);
    if (old.assetPath != widget.assetPath ||
        old.width != widget.width ||
        old.height != widget.height) {
      _hasError = false;
      if (!_isPng) {
        _loadImage();
      }
    }
  }

  Future<void> _loadImage() async {
    // Check global cache first
    final cached = RasterSvg._cache[_key];
    if (cached != null) {
      if (mounted) setState(() => _image = cached);
      return;
    }

    if (_loading) return;
    _loading = true;

    try {
      final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final int pixelW = (widget.width * pixelRatio).ceil();
      final int pixelH = (widget.height * pixelRatio).ceil();

      // Load and parse the SVG using flutter_svg's vector_graphics backend
      final pictureInfo = await vg.loadPicture(
        SvgAssetLoader(widget.assetPath),
        context,
      );

      // Rasterize to an image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Target dimensions
      final double targetW = pixelW.toDouble();
      final double targetH = pixelH.toDouble();

      // Source dimensions
      final double srcW = pictureInfo.size.width;
      final double srcH = pictureInfo.size.height;

      // Calculate uniform scale for BoxFit.cover
      final double scaleX = targetW / srcW;
      final double scaleY = targetH / srcH;
      
      // Default to cover logic if fit is cover
      final double scale = widget.fit == BoxFit.cover 
          ? (scaleX > scaleY ? scaleX : scaleY)
          : (scaleX < scaleY ? scaleX : scaleY);

      // Center the image
      final double dw = targetW - srcW * scale;
      final double dh = targetH - srcH * scale;

      canvas.translate(dw / 2, dh / 2);
      canvas.scale(scale, scale);
      canvas.drawPicture(pictureInfo.picture);

      final ui.Image image = await recorder
          .endRecording()
          .toImage(pixelW, pixelH);

      pictureInfo.picture.dispose();

      // Store in global cache
      RasterSvg._cache[_key] = image;

      if (mounted) {
        setState(() => _image = image);
      }
    } catch (e, stack) {
      debugPrint('RasterSvg error: $e\n$stack');
      if (mounted) {
        setState(() => _hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Native raster formats (PNG/JPG) are naturally fast.
    if (_isPng) {
      return Image.asset(
        widget.assetPath,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    // 2. If rasterization succeeded, show the cached texture.
    if (_image != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: RawImage(
          image: _image,
          fit: widget.fit,
          filterQuality: FilterQuality.medium,
        ),
      );
    }

    // 3. Fallback to normal live SVG if manual rasterization failed
    if (_hasError) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: SvgPicture.asset(
          widget.assetPath,
          fit: widget.fit,
        ),
      );
    }

    // 4. Loading state placeholder (transparent)
    return SizedBox(
      width: widget.width,
      height: widget.height,
    );
  }
}

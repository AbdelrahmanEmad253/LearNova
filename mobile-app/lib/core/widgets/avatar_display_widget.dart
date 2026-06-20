import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/theme/app_colors.dart';

/// Displays an avatar based on the given [avatarUrl].
///
/// - If [avatarUrl] starts with 'http', renders a network image.
/// - If [avatarUrl] matches a prefab avatar filename (e.g. 'avatar3.svg'),
///   renders the corresponding SVG asset.
/// - If [avatarUrl] is null or empty, renders the default avatar.
class AvatarDisplayWidget extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final BoxFit fit;

  const AvatarDisplayWidget({
    super.key,
    this.avatarUrl,
    this.size = 100,
    this.fit = BoxFit.cover,
  });

  bool get _isNetworkImage {
    final url = avatarUrl;
    return url != null && url.startsWith('http');
  }

  bool get _isPrefab {
    final url = avatarUrl;
    return url != null && url.isNotEmpty && !url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    if (_isNetworkImage) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColorManager.primary,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefault();
          },
        ),
      );
    }

    if (_isPrefab) {
      return SvgPicture.asset(
        AppAssets.avatarByFileName(avatarUrl!),
        width: size,
        height: size,
        fit: fit,
      );
    }

    return _buildDefault();
  }

  Widget _buildDefault() {
    return SvgPicture.asset(
      AppAssets.avatar1,
      width: size,
      height: size,
      fit: fit,
    );
  }
}

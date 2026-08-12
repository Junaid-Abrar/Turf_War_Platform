import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'shimmer_loader.dart';

/// A remote image with caching, a shimmer placeholder and a branded fallback.
///
/// Four screens previously called `Image.network` directly, each with its own
/// `errorBuilder` and no placeholder at all — so every scroll back up the venue
/// list re-downloaded the same photos and flashed white while doing it.
/// [CachedNetworkImage] holds them on disk, and a null or broken [url] lands on
/// the same fallback everywhere.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Icon shown when there is no image or it fails to load.
  final IconData fallbackIcon;
  final double fallbackIconSize;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.sports_soccer,
    this.fallbackIconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = url;

    if (imageUrl == null || imageUrl.isEmpty) {
      return _Fallback(
        width: width,
        height: height,
        icon: fallbackIcon,
        iconSize: fallbackIconSize,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Fades in rather than snapping, which hides the moment a cached image
      // resolves a frame later than the rest of the card.
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (BuildContext context, String _) => ShimmerLoader(
        child: ShimmerBox(
          width: width,
          height: height ?? 160,
          borderRadius: BorderRadius.zero,
        ),
      ),
      errorWidget: (BuildContext context, String _, Object __) => _Fallback(
        width: width,
        height: height,
        icon: fallbackIcon,
        iconSize: fallbackIconSize,
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData icon;
  final double iconSize;

  const _Fallback({
    this.width,
    this.height,
    required this.icon,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: colors.outline),
    );
  }
}

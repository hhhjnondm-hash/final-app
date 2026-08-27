import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/design_system.dart';

class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Color? placeholderColor;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(),
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 200),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? DesignSystem.bgCard,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              DesignSystem.gold.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? DesignSystem.bgCard,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 32,
          color: DesignSystem.textMuted.withOpacity(0.5),
        ),
      ),
    );
  }
}

class CachedImageWithGradient extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;
  final Widget? child;
  final BorderRadius? borderRadius;

  const CachedImageWithGradient({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
    this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
      ),
      clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: gradientBegin ?? Alignment.topCenter,
                end: gradientEnd ?? Alignment.bottomCenter,
                colors: gradientColors ??
                    [
                      Colors.transparent,
                      DesignSystem.bgDarkest.withOpacity(0.3),
                      DesignSystem.bgDarkest.withOpacity(0.7),
                    ],
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class CachedCircleImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxBorder? border;

  const CachedCircleImage({
    super.key,
    required this.imageUrl,
    this.size = 56,
    this.placeholder,
    this.errorWidget,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(),
        memCacheWidth: size.toInt(),
        memCacheHeight: size.toInt(),
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: DesignSystem.bgCard,
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              DesignSystem.gold.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: size,
      height: size,
      color: DesignSystem.bgCard,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.5,
          color: DesignSystem.textMuted.withOpacity(0.5),
        ),
      ),
    );
  }
}
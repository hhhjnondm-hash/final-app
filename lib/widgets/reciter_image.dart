import 'package:flutter/material.dart';
import '../models/audio_models.dart';
import '../services/reciter_image_resolver.dart';
import '../utils/design_system.dart';

class ReciterImage extends StatelessWidget {
  const ReciterImage({
    super.key,
    required this.reciterId,
    this.apiId,
    this.serverUrl,
    this.fit = BoxFit.cover,
    this.placeholderIconSize = 26,
  });

  final String reciterId;
  final String? apiId;
  final String? serverUrl;
  final BoxFit fit;
  final double placeholderIconSize;

  factory ReciterImage.fromProfile(
    ReciterProfile reciter, {
    Key? key,
    BoxFit fit = BoxFit.cover,
    double placeholderIconSize = 26,
  }) {
    return ReciterImage(
      key: key ?? ValueKey('reciter-image-${reciter.id}'),
      reciterId: reciter.id,
      apiId: reciter.apiId,
      serverUrl: reciter.serverUrl,
      fit: fit,
      placeholderIconSize: placeholderIconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ReciterImageResolver().resolve(
      reciterId,
      apiId: apiId,
      serverUrl: serverUrl,
    );
    if (!resolved.hasAsset) {
      return ColoredBox(
        color: DesignSystem.bgDarkest,
        child: Icon(
          Icons.person_rounded,
          color: DesignSystem.goldLight,
          size: placeholderIconSize,
        ),
      );
    }
    return Image.asset(
      resolved.assetPath!,
      fit: fit,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: DesignSystem.bgDarkest,
        child: Icon(
          Icons.person_rounded,
          color: DesignSystem.goldLight,
          size: placeholderIconSize,
        ),
      ),
    );
  }
}

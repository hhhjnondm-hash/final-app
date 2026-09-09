import 'package:flutter/material.dart';
import '../observability/dev_log.dart';
import 'reciter_image_registry.dart';

class ReciterImageResolution {
  final String reciterId;
  final String? assetPath;
  final bool isMapped;
  final String? reason;

  const ReciterImageResolution({
    required this.reciterId,
    required this.assetPath,
    required this.isMapped,
    this.reason,
  });

  bool get hasAsset => isMapped && assetPath != null && assetPath!.isNotEmpty;

  ImageProvider? get imageProvider {
    if (assetPath == null || assetPath!.isEmpty) return null;
    return AssetImage(assetPath!);
  }
}

/// UI must not construct reciter image paths. Always go through resolve().
class ReciterImageResolver {
  static final ReciterImageResolver _instance = ReciterImageResolver._internal();
  factory ReciterImageResolver() => _instance;
  ReciterImageResolver._internal();

  final ReciterImageRegistry _registry = ReciterImageRegistry();

  ReciterImageResolution resolve(String reciterId, {String? serverUrl, String? apiId}) {
    final candidates = <String>[
      reciterId,
      if (apiId != null) apiId,
      if (apiId != null) 'mp3quran_$apiId',
      ..._serverCodes(serverUrl),
    ];

    for (final id in candidates) {
      final path = _registry.lookupPath(id);
      if (path != null) {
        return ReciterImageResolution(
          reciterId: reciterId,
          assetPath: path,
          isMapped: true,
        );
      }
    }

    DevLog.image(
      message: 'unmapped reciter image',
      reciterId: reciterId,
      fallbackReason: 'no_registry_entry',
    );
    return ReciterImageResolution(
      reciterId: reciterId,
      assetPath: null,
      isMapped: false,
      reason: 'no_registry_entry',
    );
  }

  List<String> _serverCodes(String? serverUrl) {
    if (serverUrl == null || serverUrl.isEmpty) return const [];
    try {
      final uri = Uri.parse(serverUrl);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) return const [];
      return [segments.first];
    } catch (_) {
      return const [];
    }
  }
}

class ReciterAvatar extends StatelessWidget {
  final String reciterId;
  final String? serverUrl;
  final String? apiId;
  final String? legacyPhotoUrl;
  final double size;
  final double iconSize;

  const ReciterAvatar({
    super.key,
    required this.reciterId,
    this.serverUrl,
    this.apiId,
    this.legacyPhotoUrl,
    this.size = 52,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ReciterImageResolver().resolve(
      reciterId,
      serverUrl: serverUrl,
      apiId: apiId,
    );
    final path = resolved.assetPath ??
        (legacyPhotoUrl != null && legacyPhotoUrl!.startsWith('assets/')
            ? legacyPhotoUrl
            : null);

    Widget fallback = Icon(Icons.person_rounded, color: const Color(0xFFE8D48B), size: iconSize);

    if (path == null || path.isEmpty) {
      return fallback;
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        DevLog.image(
          message: 'asset failed to decode',
          reciterId: reciterId,
          assetPath: path,
          fallbackReason: 'decode_or_missing',
        );
        return fallback;
      },
    );
  }
}

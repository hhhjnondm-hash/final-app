import 'package:flutter/foundation.dart';
import '../models/canonical_identities.dart';
import '../observability/dev_log.dart';
import 'asset_validator.dart';

/// Stable reciter ID → local asset path.
/// Primary keys are MP3Quran API IDs and local canonical slugs — never display names.
class ReciterImageRegistry {
  static final ReciterImageRegistry _instance = ReciterImageRegistry._internal();
  factory ReciterImageRegistry() => _instance;
  ReciterImageRegistry._internal();

  final AssetValidator _assetValidator = AssetValidator();

  /// Canonical slug → asset path
  static const Map<String, String> _slugToAsset = {
    'hassan_saleh': 'assets/reciters/shaikh-Hassan-Saleh.webP',
    'afasy': 'assets/reciters/shaikh-Mishari-Al-afasi.webP',
    'abdulbaset_murattal': 'assets/reciters/shaikh-Abdul-Basit-Abdul-Samad.webP',
    'minshawi_murattal': 'assets/reciters/shaikh-Muhammad-Siddiq_Al-Minshawi.webP',
    'husary_murattal': 'assets/reciters/shaikh-Mahmoud-Khalil-Al-Hosary.webP',
    'hussary_murattal': 'assets/reciters/shaikh-Mahmoud-Khalil-Al-Hosary.webP',
    'maher': 'assets/reciters/shaikh-Maher-Almaikula.webP',
    'sudais': 'assets/reciters/shaikh-saood-el-shoram.webP',
    'dosari': 'assets/reciters/shaikh-Yasser-Al-Dosary.webP',
    'ajmy': 'assets/reciters/shaikh-ben-ali-elagme.webP',
    'shuraim': 'assets/reciters/shaikh-saood-el-shoram.webP',
    'banna': 'assets/reciters/shaikh-Mahmoud-Ali_Al-Banna.webP',
    'ghamdi': 'assets/reciters/shaikh-saad-el-3amde.webP',
    'abdullah_awad': 'assets/reciters/Abdullah-Awad-Al-Juhani.webP',
    'abdullah_juhany': 'assets/reciters/Abdullah-Awad-Al-Juhani.webP',
    'abdul_ilah_aoun': 'assets/reciters/shaikh-Abdul-Ilah-bin-Aoun.webP',
    'abdulilah_aoun': 'assets/reciters/shaikh-Abdul-Ilah-bin-Aoun.webP',
    'abdul_rahman_aws': 'assets/reciters/shaikh-Abdul-Rahman-Al-Aws.webP',
    'abdul_rahman_majid': 'assets/reciters/shaikh-Abdul-Rahman-Al-Majid.webP',
    'abdulrahman_majid': 'assets/reciters/shaikh-Abdul-Rahman-Al-Majid.webP',
    'abdulaziz_zahran': 'assets/reciters/shaikh-Abdulaziz-Al-Zahran.webP',
    'abdullah_kamel': 'assets/reciters/shaikh-Abdullah-Kamel.webP',
    'adel_rayyan': 'assets/reciters/shaikh-Adel-Rayyan.webP',
    'ahmed_nafis': 'assets/reciters/shaikh-Ahmed-Al-Nafis.webP',
    'al_fatih_zubair': 'assets/reciters/shaikh-Al-Fatih-Muhammad-Al-Zubair.webP',
    'alfatih_zubair': 'assets/reciters/shaikh-Al-Fatih-Muhammad-Al-Zubair.webP',
    'bisha_qadir': 'assets/reciters/shaikh-Bisha-wa-Qadir-Al-Kurdi.webP',
    'fares_abbad': 'assets/reciters/shaikh-Fares-Abbad.webP',
    'hatem_farid': 'assets/reciters/shaikh-Hatem-Farid-Al-Waer.webP',
    'hisham_haraz': 'assets/reciters/shaikh-Hisham-Al-Haraz.webP',
    'ibrahim_jarmi': 'assets/reciters/shaikh-Ibrahim-Al-Jarmi.webP',
    'juman_osaimi': 'assets/reciters/shaikh-Juman-Al-Osaimi.webP',
    'maher_almaikula': 'assets/reciters/shaikh-Maher-Almaikula.webP',
    'mahmoud_rifai': 'assets/reciters/shaikh-Mahmoud-Al-Rifai.webP',
    'mahmoud_banna': 'assets/reciters/shaikh-Mahmoud-Ali_Al-Banna.webP',
    'mansour_salmi': 'assets/reciters/shaikh-Mansour-Al-Salmi.webP',
    'mohammad_kareem': 'assets/reciters/shaikh-Mohammad-Abd-Al-Kareem.webP',
    'muhammad_tablawi': 'assets/reciters/shaikh-Muhammad-Al-Tablawi.webP',
    'tablawi': 'assets/reciters/shaikh-Muhammad-Al-Tablawi.webP',
    'muhammad_jibril': 'assets/reciters/shaikh-Muhammad-Jibril.webP',
    'muhammad_jibreel': 'assets/reciters/shaikh-Muhammad-Jibril.webP',
    'nabil_rifai': 'assets/reciters/shaikh-Nabil-Al-Rifai.webP',
    'khaled_jileel': 'assets/reciters/shaikh-khaled-galel.webP',
    'abubakr_shatery': 'assets/reciters/shaikh-abubakr-as-shatery.webP',
    'abu_bakr_shatri': 'assets/reciters/shaikh-abubakr-as-shatery.webP',
    'khaled_kahtany': 'assets/reciters/shaikh-khaled-el-kahtany.webP',
    'khaled_qahtani': 'assets/reciters/shaikh-khaled-el-kahtany.webP',
    'abdul_rahman_shahat': 'assets/reciters/shaikh-Abdul-Rahman-Al-Shahat.webP',
    'abdulrahman_shahat': 'assets/reciters/shaikh-Abdul-Rahman-Al-Shahat.webP',
    'adel_kalbani': 'assets/reciters/shiekh-Adel-Al-Kalbani.webP',
    'bandar_balila': 'assets/reciters/shiekh-Bandar-Balila.webP',
    'bandar_baleela': 'assets/reciters/shiekh-Bandar-Balila.webP',
    'mohammad_ayoub': 'assets/reciters/shaikh-Mohamed-Ayoub.webP',
    'muhammad_ayyoub': 'assets/reciters/shaikh-Mohamed-Ayoub.webP',
    'raad_kurdi': 'assets/reciters/shaikh-Raad-Muhammad-Al-Kurdi.webP',
    'salah_boukater': 'assets/reciters/shaikh-Salah-Bou-Khater.webP',
    'salah_bukhatir': 'assets/reciters/shaikh-Salah-Bou-Khater.webP',
    'noreen_siddiq': 'assets/reciters/shaikh-Noreen-Muhammad-Siddiq.webP',
    'yasser_salama': 'assets/reciters/shaikh-Yasser-Salama.webP',
    'naser_katamy': 'assets/reciters/shaikh-Naser-Al-Katamy.webP',
  };

  /// Official MP3Quran server folder → local slug
  static const Map<String, String> serverCodeToSlug = {
    'afs': 'afasy',
    'h_saleh': 'hassan_saleh',
    'basit': 'abdulbaset_murattal',
    'minsh': 'minshawi_murattal',
    'husr': 'husary_murattal',
    'husary': 'husary_murattal',
    'maher': 'maher',
    'yasser': 'dosari',
    'ajm': 'ajmy',
    's_gmd': 'ghamdi',
    'shur': 'shuraim',
    'bna': 'banna',
    'tblwi': 'tablawi',
    'frs_a': 'fares_abbad',
    'jleel': 'khaled_jileel',
    'shatri': 'abu_bakr_shatri',
    'jhn': 'abdullah_juhany',
    'bu_khtr': 'salah_bukhatir',
    'jbrl': 'muhammad_jibreel',
    'ayyub': 'muhammad_ayyoub',
    'qht': 'khaled_qahtani',
    'rifai': 'nabil_rifai',
    'hatem': 'hatem_farid',
    'balila': 'bandar_baleela',
    'kalbani': 'adel_kalbani',
    'majid': 'abdulrahman_majid',
    'aoun': 'abdulilah_aoun',
    'zahran': 'abdulaziz_zahran',
    'kamel': 'abdullah_kamel',
    'rayyan': 'adel_rayyan',
    'nafis': 'ahmed_nafis',
    'alfatih': 'alfatih_zubair',
    'haraz': 'hisham_haraz',
    'jarmi': 'ibrahim_jarmi',
    'juman': 'juman_osaimi',
    'm_rifai': 'mahmoud_rifai',
    'salmi': 'mansour_salmi',
    'kareem': 'mohammad_kareem',
    'noreen': 'noreen_siddiq',
    'raad': 'raad_kurdi',
    'salama': 'yasser_salama',
    'naser': 'naser_katamy',
    'sudais': 'sudais',
    'sds': 'sudais',
  };

  final Map<String, bool> _assetValidationCache = {};
  bool _isValidated = false;

  String? pathForSlug(String slug) => _slugToAsset[slug];

  /// Resolve any known identity token to an asset path, or null if unmapped.
  String? lookupPath(String reciterId) {
    final id = reciterId.trim();
    if (id.isEmpty) return null;

    if (_slugToAsset.containsKey(id)) return _slugToAsset[id];

    if (id.startsWith('mp3quran_')) {
      final rest = id.substring('mp3quran_'.length);
      if (_slugToAsset.containsKey(rest)) return _slugToAsset[rest];
    }

    final fromServer = serverCodeToSlug[id];
    if (fromServer != null) return _slugToAsset[fromServer];

    return null;
  }

  bool hasImage(String reciterId) => lookupPath(reciterId) != null;

  List<String> getAvailableReciterIds() => _slugToAsset.keys.toList();

  Future<void> validateAssets() async {
    _isValidated = true;
    for (final entry in _slugToAsset.entries) {
      final result = await _assetValidator.validateAssetDetailed(entry.value);
      _assetValidationCache[entry.key] = result.isValid;
      if (!result.isValid) {
        DevLog.image(
          message: 'asset missing',
          reciterId: entry.key,
          assetPath: entry.value,
          fallbackReason: result.error,
        );
      }
    }
  }

  bool isAssetValid(String reciterId) {
    if (!_isValidated) return true;
    final slug = _canonicalSlug(reciterId);
    if (slug == null) return false;
    return _assetValidationCache[slug] ?? false;
  }

  String? _canonicalSlug(String reciterId) {
    if (_slugToAsset.containsKey(reciterId)) return reciterId;
    return serverCodeToSlug[reciterId];
  }

  String? resolveImage(ReciterIdentity reciter) {
    return lookupPath(reciter.localAssetKey) ??
        lookupPath(reciter.canonicalId) ??
        lookupPath(reciter.apiId ?? '');
  }

  /// Backward compatibility alias for getImagePath
  String? getImagePath(String? reciterId) => lookupPath(reciterId ?? '');

  Map<String, dynamic> getValidationReport() {
    final validCount = _assetValidationCache.values.where((v) => v).length;
    final invalidCount = _assetValidationCache.values.where((v) => !v).length;
    return {
      'totalAssets': _slugToAsset.length,
      'validatedAssets': _assetValidationCache.length,
      'validAssets': validCount,
      'invalidAssets': invalidCount,
      'validationComplete': _isValidated,
      'invalidAssetsList': _assetValidationCache.entries
          .where((e) => !e.value)
          .map((e) => e.key)
          .toList(),
    };
  }

  void clearValidationCache() {
    _assetValidationCache.clear();
    _isValidated = false;
  }

  @visibleForTesting
  Map<String, String> get slugMapForTest => Map.unmodifiable(_slugToAsset);
}
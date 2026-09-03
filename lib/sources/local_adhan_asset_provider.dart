import '../models/prayer_models.dart';
import '../services/adhan_asset_mapper.dart';
import 'source_contracts.dart';

class LocalAdhanAssetProvider implements AdhanProvider {
  static final LocalAdhanAssetProvider _instance = LocalAdhanAssetProvider._internal();
  factory LocalAdhanAssetProvider() => _instance;
  LocalAdhanAssetProvider._internal();

  @override
  String assetPathFor(String prayerKey) {
    final type = PrayerType.values.firstWhere(
      (p) => p.name == prayerKey.toLowerCase(),
      orElse: () => PrayerType.fajr,
    );
    return AdhanAssetMapper.getAssetPath(type);
  }
}

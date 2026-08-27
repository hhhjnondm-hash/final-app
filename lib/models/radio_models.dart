enum RadioCategory {
  all,
  quran,
  hadith,
  sciences,
  lessons,
  nasheed,
  adhkar,
  tafsir,
}

class RadioStation {
  final String id;
  final String name;
  final String origin;
  final String description;
  final String streamUrl;
  final RadioCategory category;
  final String listenersCount;
  final String currentProgram;
  final String quality;
  final String? photoUrl;
  final bool isLive;

  const RadioStation({
    required this.id,
    required this.name,
    required this.origin,
    required this.description,
    required this.streamUrl,
    required this.category,
    this.listenersCount = '١٢.٤K مستمع',
    this.currentProgram = 'تلاوة خاشعة وبرامج إيمانية متواصلة',
    this.quality = 'جودة عالية (128 kbps)',
    this.photoUrl,
    this.isLive = true,
  });
}

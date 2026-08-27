# Islamyat App (رفيق)

تطبيق إسلامي شامل متعدد المنصات مبني بـ Flutter، يوفر تجربة روحانية متكاملة للمسلمين حول العالم.

## 🌟 المميزات الرئيسية

### 📖 القرآن الكريم
- عرض السور والآيات بتنسيق جميل
- أكثر من 50 قارئ مشهور
- تشغيل صوتي متقدم مع خيارات متعددة
- إمكانية حفظ الآيات المفضلة
- التفسير والترجمة

### 🕌 مواقيت الصلاة
- حساب دقيق لمواقيت الصلاة حسب الموقع
- إشعارات الأذان الحقيقية
- تحديد اتجاه القبلة بالبوصلة
- تنبيهات ذكية للصلوات
- دعم مدن متعددة حول العالم

### 📿 الأذكار والأدعية
- أذكار الصباح والمساء
- أذكار متنوعة ومقسمة حسب الأوقات
- سبحة إلكترونية ذكية
- تذكيرات إيمانية يومية
- إمكانية إضافة أذكار مخصصة

### 📚 الأحاديث النبوية
- مجموعة مختارة من الأحاديث الصحيحة
- أحاديث من صحيح البخاري ومسلم ورياض الصالحين
- تصنيف وتنظيم الأحاديث
- البحث والمشاركة

### 🎙️ الصوتيات
- إذاعات قرآنية مباشرة
- محطات إذاعية إسلامية متعددة
- مشغل صوتي متقدم
- إمكانية التسجيل والاستماع

### 🧭 القبلة
- بوصلة دقيقة لتحديد اتجاه القبلة
- حساب المسافة للكعبة
- دعم تحديد الموقع الجغرافي

### 📱 الميزات التقنية
- تصميم عصري وجذاب
- دعم الوضع الليلي
- واجهة سهلة الاستخدام
- حفظ الإعدادات المفضلة
- دعم اللغات المتعددة (العربية والإنجليزية)
- إشعارات ذكية
- وضع عدم الاتصال

## 🛠️ التقنيات المستخدمة

### Core Framework
- **Flutter**: إطار العمل الرئيسي
- **Dart**: لغة البرمجة

### State Management
- **Provider**: إدارة الحالة

### Storage
- **shared_preferences**: حفظ الإعدادات البسيطة
- **Hive**: قاعدة بيانات محلية سريعة

### Location Services
- **geolocator**: تحديد الموقع الجغرافي

### Notifications
- **flutter_local_notifications**: إشعارات محلية متقدمة

### Networking & Images
- **cached_network_image**: تحميل وتخزين الصور بكفاءة

### Internationalization
- **easy_localization**: دعم اللغات المتعددة

### Error Handling
- **sentry_flutter**: رصد الأخطاء وتتبعها

## 📋 المتطلبات

- Flutter SDK >= 3.13.1
- Dart SDK >= 3.13.1
- Android Studio / Xcode (للتطوير)
- Git

## 🚀 التثبيت والتشغيل

### 1. استنساخ المشروع
```bash
git clone <repository-url>
cd islamyat_app
```

### 2. تثبيت المكتبات
```bash
flutter pub get
```

### 3. تشغيل المشروع
```bash
# على محاكي Android
flutter run

# على محاكي iOS
flutter run -d ios

# على الويب
flutter run -d chrome
```

### 4. بناء المشروع
```bash
# بناء تطبيق Android
flutter build apk --release

# بناء تطبيق iOS
flutter build ios --release

# بناء تطبيق الويب
flutter build web --release
```

## 📁 هيكل المشروع

```
lib/
├── main.dart                 # نقطة البداية
├── l10n/                     # ملفات الترجمة
│   ├── app_ar.arb
│   ├── app_en.arb
│   └── localization.dart
├── models/                   # نماذج البيانات
│   ├── quran_models.dart
│   ├── prayer_models.dart
│   ├── azkar_models.dart
│   ├── hadith_models.dart
│   ├── audio_models.dart
│   ├── notification_models.dart
│   └── hive_models.dart
├── services/                 # الخدمات
│   ├── storage_service.dart
│   ├── location_service.dart
│   ├── notification_service.dart
│   ├── prayer_service.dart
│   ├── quran_service.dart
│   ├── azkar_service.dart
│   ├── hadith_service.dart
│   ├── audio_player_engine.dart
│   ├── radio_service.dart
│   ├── hive_database_service.dart
│   ├── error_handler.dart
│   └── app_initializer.dart
├── providers/               # إدارة الحالة
│   └── user_preferences_provider.dart
├── screens/                  # الشاشات
│   ├── home_screen.dart
│   ├── quran_screen.dart
│   ├── prayer_times_screen.dart
│   ├── azkar_screen.dart
│   ├── audio_screen.dart
│   ├── hadith_screen.dart
│   ├── profile_screen.dart
│   ├── qibla_screen.dart
│   ├── tasbih_screen.dart
│   └── ...
├── widgets/                  # العناصر القابلة لإعادة الاستخدام
│   ├── cached_image.dart
│   ├── surah_card.dart
│   ├── dhikr_card.dart
│   ├── hadith_card.dart
│   ├── prayer_hero_card.dart
│   └── ...
├── data/                     # البيانات الثابتة
│   ├── quran_metadata.dart
│   ├── hadith_data.dart
│   ├── all_azkar_data.dart
│   ├── morning_azkar_data.dart
│   ├── radio_data.dart
│   └── reciters_data.dart
└── utils/                    # الأدوات المساعدة
    └── design_system.dart
```

## 🔧 الإعدادات

### إعدادات الموقع
يحتاج التطبيق إلى إذن الموقع لتحديد مواقيت الصلاة واتجاه القبلة بدقة. تأكد من منح الإذن المطلوب.

### إعدادات الإشعارات
للحصول على تنبيهات الصلاة، تأكد من تفعيل إشعارات التطبيق في إعدادات الجهاز.

### إعدادات التخزين
يحتاج التطبيق إلى إذن التخزين لحفظ الملفات الصوتية للاستماع دون اتصال.

## 🧪 الاختبارات

```bash
# تشغيل جميع الاختبارات
flutter test

# تشغيل اختبارات معينة
flutter test test/widget_test.dart

# تشغيل الاختبارات مع التغطية
flutter test --coverage
```

## 📱 البناء للأجهزة المختلفة

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Windows
```bash
flutter build windows --release
```

### Linux
```bash
flutter build linux --release
```

### macOS
```bash
flutter build macos --release
```

## 🤝 المساهمة

نرحب بمساهماتكم! لتحسين المشروع:

1. Fork المشروع
2. أنشئ فرع للميزة الجديدة (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push إلى الفرع (`git push origin feature/AmazingFeature`)
5. افتح Pull Request

## 📄 الترخيص

هذا المشروع مرخص تحت رخصة MIT - انظر ملف LICENSE للتفاصيل.

## 📞 التواصل

للتواصل والدعم:
- البريد الإلكتروني: support@islamyat.com
- الموقع: www.islamyat.com

## 🙏 شكر وتقدير

- جميع القراء والقارئات للمواد الصوتية
- المصادر الإسلامية للمحتوى الديني
- مجتمع Flutter المفتوح المصدر

## 📝 ملاحظات مهمة

- التطبيق يحتاج إلى اتصال بالإنترنت لتحميل المواد الصوتية والبيانات
- إشعارات الصلاة تعتمد على إعدادات الموقع الجغرافي
- يُنصح بالاتصال بالشبكة Wi-Fi لتحميل المواد الكبيرة
- التطبيق يدعم اللغتين العربية والإنجليزية بشكل كامل

## 🔄 التحديثات المستقبلية

- [ ] إضافة المزيد من القراء
- [ ] دعم المزيد من اللغات
- [ ] ميزات اجتماعية (مشاركة التلاوة)
- [ ] إحصائيات وتقدم شخصي
- [ ] وضع خاص لشهر رمضان
- [ ] دعم الأذكار الصوتية
- [ ] مكتبة الكتب الإسلامية

---

**صنع بـ ❤️ للمسلمين حول العالم**
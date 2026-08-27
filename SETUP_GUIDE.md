# دليل التثبيت والإعداد لتطبيق رفيق

هذا الدليل يشرح كيفية إعداد وتثبيت المكتبات والميزات الجديدة المضافة لتطبيق رفيق.

## 📦 المكتبات الجديدة المضافة

### 1. إدارة الحالة
- **provider**: ^6.1.1 - لإدارة الحالة في التطبيق

### 2. التخزين المحلي
- **shared_preferences**: ^2.2.2 - لحفظ الإعدادات البسيطة
- **hive**: ^2.2.3 - قاعدة بيانات محلية سريعة
- **hive_flutter**: ^1.1.0 - دعم Hive لـ Flutter
- **hive_generator**: ^2.0.1 - لتوليد أكواد Hive
- **build_runner**: ^2.4.8 - لبناء الأكواد المولدة

### 3. الموقع الجغرافي
- **geolocator**: ^10.1.0 - لتحديد الموقع الجغرافي

### 4. الإشعارات
- **flutter_local_notifications**: ^16.3.0 - لإشعارات محلية متقدمة
- **timezone**: ^0.9.2 - لدعم التوقيتات في الإشعارات

### 5. الصور
- **cached_network_image**: ^3.3.1 - لتحميل وتخزين الصور بكفاءة

### 6. التعريب
- **easy_localization**: ^3.0.3 - لدعم اللغات المتعددة

### 7. معالجة الأخطاء
- **sentry_flutter**: ^7.14.0 - لرصد الأخطاء وتتبعها

## 🚀 خطوات التثبيت

### 1. تثبيت المكتبات
```bash
flutter pub get
```

### 2. توليد أكواد Hive
بعد إضافة موديلات Hive، يجب توليد الأكواد:

```bash
flutter pub run build_runner build
```

إذا واجهت مشاكل، استخدم:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. إضافة ملفات الصوت (للإشعارات)
يحتاج التطبيق إلى ملفات صوتية للأذان. أضف الملفات التالية:

#### Android
أضف ملفات الصوت إلى `android/app/src/main/res/raw/`:
- `athan.mp3` - صوت الأذان

#### iOS
أضف ملفات الصوت إلى `ios/Runner/`:
- `athan.aiff` - صوت الأذان

### 4. إضافة إذن الموقع

#### Android
أضف الإذن إلى `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

لـ Android 13+، أضف أيضاً:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### iOS
أضف الإذن إلى `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>يحتاج التطبيق إلى موقعك لتحديد مواقيت الصلاة واتجاه القبلة بدقة</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>يحتاج التطبيق إلى موقعك لتحديد مواقيت الصلاة حتى عندما يكون التطبيق في الخلفية</string>
```

### 5. إضافة إذن الإشعارات

#### Android
أضف الإذن إلى `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### iOS
أضف الإذن إلى `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 6. إضافة إذن التخزين (للأجهزة القديمة)

#### Android
أضف الإذن إلى `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 7. إعداد Sentry (اختياري)
إذا كنت تريد استخدام Sentry لرصد الأخطاء:

1. سجل حساب على [Sentry.io](https://sentry.io)
2. أنشئ مشروع جديد
3. احصل على DSN
4. أضف DSN في `lib/services/error_handler.dart`:

```dart
await SentryFlutter.init(
  (options) => options.dsn = 'YOUR_SENTRY_DSN_HERE',
);
```

## 🔧 إعداد اللغات

### ملفات الترجمة
تم إضافة ملفات الترجمة في `lib/l10n/`:
- `app_ar.arb` - الترجمة العربية
- `app_en.arb` - الترجمة الإنجليزية

### إضافة لغة جديدة
1. أنشئ ملف `app_xx.arb` (حيث xx هو رمز اللغة)
2. أضف الترجمات المطلوبة
3. أضف اللغة إلى `lib/l10n/localization.dart`:

```dart
static const List<Locale> supportedLocales = [
  Locale('ar', 'SA'),
  Locale('en', 'US'),
  Locale('fr', 'FR'), // اللغة الجديدة
];
```

## 🧪 تشغيل الاختبارات

```bash
# تشغيل جميع الاختبارات
flutter test

# تشغيل الاختبارات مع التغطية
flutter test --coverage
```

## 📱 تشغيل التطبيق

### على محاكي Android
```bash
flutter run
```

### على محاكي iOS
```bash
flutter run -d ios
```

### على الويب
```bash
flutter run -d chrome
```

## 🐛 استكشاف الأخطاء

### مشاكل في Hive
إذا واجهت مشاكل في Hive:

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### مشاكل في الموقع
تأكد من:
- تفعيل GPS على الجهاز
- منح إذن الموقع للتطبيق
- تفعيل خدمات الموقع في إعدادات الجهاز

### مشاكل في الإشعارات
تأكد من:
- تفعيل الإشعارات في إعدادات الجهاز
- منح إذن الإشعارات للتطبيق
- وجود ملفات الصوت المطلوبة

### مشاكل في الترجمة
تأكد من:
- وجود ملفات الترجمة في `lib/l10n/`
- تهيئة `easy_localization` في `main.dart`
- إضافة اللغات المدعومة في `localization.dart`

## 📊 مراقبة الأداء

### باستخدام Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### رصد الأخطاء باستخدام Sentry
بعد إعداد Sentry، ستظهر الأخطاء في لوحة تحكم Sentry.

## 🔄 التحديث المستمر

### تحديث المكتبات
```bash
flutter pub upgrade
```

### تحديث إصدار Flutter
```bash
flutter upgrade
```

## 📚 ملاحظات مهمة

1. **الاختبارات**: تأكد من تشغيل الاختبارات قبل كل تغيير كبير
2. **النسخ الاحتياطي**: احفظ نسخة احتياطية قبل التحديثات الكبيرة
3. **الأذونات**: تأكد من شرح الأذونات للمستخدمين في سياسة الخصوصية
4. **الأخطاء**: راقب الأخطاء بانتظام باستخدام Sentry
5. **الأداء**: راقب أداء التطبيق باستخدام DevTools

## 🆘 الدعم

إذا واجهت مشاكل:
1. راجع هذا الدليل
2. راجع وثائق Flutter الرسمية
3. راجل وثائق كل مكتبة
4. راجع ملف `TESTING.md` للاختبارات

---

**تم التحديث:** 2026-08-27
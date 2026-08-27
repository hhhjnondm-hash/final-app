# اختبارات تطبيق رفيق (Islamyat App Tests)

هذا المستند يشرح كيفية تشغيل وتطوير الاختبارات لتطبيق رفيق.

## 🧪 هيكل الاختبارات

تم تنظيم الاختبارات في المجلدات التالية:

```
test/
├── widget_test.dart           # اختبار التطبيق الأساسي
├── services/                  # اختبارات الخدمات
│   ├── storage_service_test.dart
│   └── error_handler_test.dart
├── providers/                 # اختبارات إدارة الحالة
│   └── user_preferences_provider_test.dart
├── models/                    # اختبارات النماذج
│   └── hive_models_test.dart
└── widgets/                   # اختبارات العناصر
    └── cached_image_test.dart
```

## 🚀 تشغيل الاختبارات

### تشغيل جميع الاختبارات
```bash
flutter test
```

### تشغيل اختبارات معينة
```bash
# اختبار خدمة التخزين
flutter test test/services/storage_service_test.dart

# اختبار معالج الأخطاء
flutter test test/services/error_handler_test.dart

# اختبار تفضيلات المستخدم
flutter test test/providers/user_preferences_provider_test.dart

# اختبار نماذج Hive
flutter test test/models/hive_models_test.dart

# اختبار الصور المحملة
flutter test test/widgets/cached_image_test.dart
```

### تشغيل الاختبارات مع التغطية
```bash
flutter test --coverage
```

### تشغيل الاختبارات على جهاز معين
```bash
flutter test -d chrome
flutter test -d android
flutter test -d ios
```

## 📊 تقرير التغطية

بعد تشغيل الاختبارات مع التغطية، يمكنك رؤية تقرير التغطية:

```bash
# إنشاء تقرير HTML
genhtml coverage/lcov.info -o coverage/html

# فتح التقرير في المتصفح
open coverage/html/index.html
```

## 🧪 أنواع الاختبارات

### 1. اختبارات الوحدة (Unit Tests)
تختبر المكونات الفردية بشكل منفصل:
- `storage_service_test.dart` - اختبارات خدمة التخزين
- `error_handler_test.dart` - اختبارات معالج الأخطاء
- `user_preferences_provider_test.dart` - اختبارات تفضيلات المستخدم
- `hive_models_test.dart` - اختبارات نماذج البيانات

### 2. اختبارات العناصر (Widget Tests)
تختبر العناصر الواجهة بشكل منفصل:
- `cached_image_test.dart` - اختبارات عنصر الصور المحملة
- `widget_test.dart` - اختبار التطبيق الأساسي

### 3. اختبارات التكامل (Integration Tests)
تختبر تفاعل المكونات معاً:
- اختبارات في `widget_test.dart` للتحقق من تدفق التطبيق

## 📝 كتابة اختبارات جديدة

### إضافة اختبار خدمة جديدة

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:islamyat_app/services/your_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YourService Tests', () {
    late YourService service;

    setUp(() async {
      service = YourService();
      await service.init();
    });

    test('should do something', () async {
      // Arrange
      final input = 'test';

      // Act
      final result = await service.doSomething(input);

      // Assert
      expect(result, equals('expected'));
    });
  });
}
```

### إضافة اختبار عنصر جديد

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamyat_app/widgets/your_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YourWidget Tests', () {
    testWidgets('should render with default parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YourWidget(),
          ),
        ),
      );

      expect(find.byType(YourWidget), findsOneWidget);
    });

    testWidgets('should respond to user interaction', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YourWidget(),
          ),
        ),
      );

      await tester.tap(find.byType(YourWidget));
      await tester.pump();

      expect(find.text('Expected Text'), findsOneWidget);
    });
  });
}
```

## 🎯 أفضل الممارسات

### 1. تنظيم الاختبارات
- اجعل كل اختبار يركز على شيء واحد فقط
- استخدم `group` لتنظيم الاختبارات ذات الصلة
- استخدم أسماء واضحة وموصوفة للاختبارات

### 2. استخدام setUp و tearDown
```dart
setUp(() async {
  // تهيئة الحالة المشتركة
});

tearDown(() async {
  // تنظيف الحالة
});
```

### 3. اختبار الحالات المختلفة
```dart
test('should handle valid input', () async {
  // اختبار الحالة الطبيعية
});

test('should handle invalid input', () async {
  // اختبار الحالة غير الطبيعية
});

test('should handle edge cases', () async {
  // اختبار الحالات الحدية
});
```

### 4. استخدام Mocks
```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([YourService])
void main() {
  test('should use mocked service', () async {
    final mockService = MockYourService();
    when(mockService.getData()).thenAnswer((_) async => 'mocked data');
    
    // Use mockService in your test
  });
}
```

## 🔍 استكشاف الأخطاء

### الاختبارات تفشل بسبب الاعتمادات
تأكد من أن جميع المكتبات المطلوبة موجودة في `pubspec.yaml`:

```bash
flutter pub get
```

### الاختبارات تفشل بسبب التهيئة
تأكد من تهيئة Flutter Test:

```dart
TestWidgetsFlutterBinding.ensureInitialized();
```

### اختبارات الشبكة تفشل
استخدم `MockService` لمحاكاة استجابات الشبكة:

```dart
when(mockService.fetchData()).thenAnswer((_) async => mockData);
```

## 📈 تحسين التغطية

### تحسين تغطية الخدمات
- أضف اختبارات لجميع الدوال العامة
- اختبر حالات النجاح والفشل
- اختبر معالجة الأخطاء

### تحسين تغطية العناصر
- اختبر جميع الحالات الممكنة للعنصر
- اختبر التفاعل مع المستخدم
- اختبر الحالات الحدية

### تحسين تغطية النماذج
- اختبر جميع الخصائص
- اختبر طرق النسخ والتعديل
- اختبر الحسابات والتحويلات

## 🔄 التكامل المستمر

يمكنك إضافة الاختبارات إلى CI/CD pipeline:

```yaml
# .github/workflows/test.yml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.13.1'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v2
```

## 📚 الموارد الإضافية

- [Flutter Testing Documentation](https://docs.flutter.dev/cookbook/testing)
- [Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Unit Testing Guide](https://docs.flutter.dev/cookbook/testing/unit/introduction)
- [Mockito Package](https://pub.dev/packages/mockito)

---

**ملاحظة:** تأكد من تشغيل `flutter pub get` قبل تشغيل الاختبارات للتأكد من تثبيت جميع المكتبات المطلوبة.
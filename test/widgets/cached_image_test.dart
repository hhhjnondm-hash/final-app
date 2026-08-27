import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamyat_app/widgets/cached_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CachedImage Widget Tests', () {
    testWidgets('should render with default parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(CachedImage), findsOneWidget);
    });

    testWidgets('should render with custom fit', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedImage(
              imageUrl: 'https://example.com/image.jpg',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );

      expect(find.byType(CachedImage), findsOneWidget);
    });

    testWidgets('should render with border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedImage(
              imageUrl: 'https://example.com/image.jpg',
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );

      expect(find.byType(CachedImage), findsOneWidget);
    });

    testWidgets('should render with custom border', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedImage(
              imageUrl: 'https://example.com/image.jpg',
              border: Border.all(color: Colors.red, width: 2),
            ),
          ),
        ),
      );

      expect(find.byType(CachedImage), findsOneWidget);
    });

    testWidgets('should render with box shadow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedImage(
              imageUrl: 'https://example.com/image.jpg',
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CachedImage), findsOneWidget);
    });
  });

  group('CachedImageWithGradient Widget Tests', () {
    testWidgets('should render with gradient overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedImageWithGradient(
              imageUrl: 'https://example.com/image.jpg',
              gradientColors: [
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CachedImageWithGradient), findsOneWidget);
    });

    testWidgets('should render with child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedImageWithGradient(
              imageUrl: 'https://example.com/image.jpg',
              child: const Text('Overlay Text'),
            ),
          ),
        ),
      );

      expect(find.byType(CachedImageWithGradient), findsOneWidget);
      expect(find.text('Overlay Text'), findsOneWidget);
    });

    testWidgets('should render with custom gradient direction', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedImageWithGradient(
              imageUrl: 'https://example.com/image.jpg',
              gradientBegin: Alignment.topLeft,
              gradientEnd: Alignment.bottomRight,
            ),
          ),
        ),
      );

      expect(find.byType(CachedImageWithGradient), findsOneWidget);
    });
  });

  group('CachedCircleImage Widget Tests', () {
    testWidgets('should render as circle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedCircleImage(
              imageUrl: 'https://example.com/image.jpg',
              size: 80,
            ),
          ),
        ),
      );

      expect(find.byType(CachedCircleImage), findsOneWidget);
    });

    testWidgets('should render with custom size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedCircleImage(
              imageUrl: 'https://example.com/image.jpg',
              size: 120,
            ),
          ),
        ),
      );

      expect(find.byType(CachedCircleImage), findsOneWidget);
    });

    testWidgets('should render with border', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedCircleImage(
              imageUrl: 'https://example.com/image.jpg',
              size: 80,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      );

      expect(find.byType(CachedCircleImage), findsOneWidget);
    });

    testWidgets('should render with default size if not specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedCircleImage(
              imageUrl: 'https://example.com/image.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(CachedCircleImage), findsOneWidget);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:islamyat_app/services/error_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorHandler Tests', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
      errorHandler.clearErrors();
    });

    test('should create error from exception', () {
      final exception = Exception('Test error');
      final error = AppError.fromException(exception);

      expect(error.message, contains('Test error'));
      expect(error.type, equals(ErrorType.unknown));
      expect(error.severity, equals(ErrorSeverity.medium));
    });

    test('should create error with custom type and severity', () {
      final exception = Exception('Network error');
      final error = AppError.fromException(
        exception,
        type: ErrorType.network,
        severity: ErrorSeverity.high,
      );

      expect(error.type, equals(ErrorType.network));
      expect(error.severity, equals(ErrorSeverity.high));
    });

    test('should handle error and add to errors list', () {
      final initialErrorCount = errorHandler.errors.length;
      errorHandler.handleError(
        Exception('Test error'),
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        showDialog: false,
      );

      expect(errorHandler.errors.length, equals(initialErrorCount + 1));
    });

    test('should filter errors by type', () {
      errorHandler.handleError(
        Exception('Network error'),
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        showDialog: false,
      );

      errorHandler.handleError(
        Exception('Storage error'),
        type: ErrorType.storage,
        severity: ErrorSeverity.high,
        showDialog: false,
      );

      final networkErrors = errorHandler.getErrorsByType(ErrorType.network);
      final storageErrors = errorHandler.getErrorsByType(ErrorType.storage);

      expect(networkErrors.length, equals(1));
      expect(storageErrors.length, equals(1));
      expect(networkErrors.first.type, equals(ErrorType.network));
      expect(storageErrors.first.type, equals(ErrorType.storage));
    });

    test('should filter errors by severity', () {
      errorHandler.clearErrors(); // Clear previous errors
      
      errorHandler.handleError(
        Exception('Low severity error'),
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        showDialog: false,
      );

      errorHandler.handleError(
        Exception('High severity error'),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        showDialog: false,
      );

      final lowSeverityErrors = errorHandler.getErrorsBySeverity(ErrorSeverity.low);
      final highSeverityErrors = errorHandler.getErrorsBySeverity(ErrorSeverity.high);

      expect(lowSeverityErrors.length, equals(1));
      expect(highSeverityErrors.length, equals(1));
      expect(lowSeverityErrors.first.severity, equals(ErrorSeverity.low));
      expect(highSeverityErrors.first.severity, equals(ErrorSeverity.high));
    });

    test('should clear all errors', () {
      errorHandler.handleError(
        Exception('Test error 1'),
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        showDialog: false,
      );

      errorHandler.handleError(
        Exception('Test error 2'),
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        showDialog: false,
      );

      expect(errorHandler.hasErrors, isTrue);

      errorHandler.clearErrors();

      expect(errorHandler.hasErrors, isFalse);
      expect(errorHandler.errors.length, equals(0));
    });

    test('should convert error to JSON', () {
      final error = AppError(
        message: 'Test error',
        technicalDetails: 'Technical details',
        type: ErrorType.network,
        severity: ErrorSeverity.high,
        timestamp: DateTime.now(),
      );

      final json = error.toJson();

      expect(json['message'], equals('Test error'));
      expect(json['technicalDetails'], equals('Technical details'));
      expect(json['type'], equals('network'));
      expect(json['severity'], equals('high'));
    });

    test('should maintain error limit (max 100 errors)', () async {
      // Add more than 100 errors
      for (int i = 0; i < 150; i++) {
        errorHandler.handleError(
          Exception('Error $i'),
          type: ErrorType.unknown,
          severity: ErrorSeverity.low,
          showDialog: false,
        );
      }

      expect(errorHandler.errors.length, lessThanOrEqualTo(100));
    });
  });

  group('ErrorHelpers Tests', () {
    test('should get appropriate error message for network error', () {
      final message = ErrorHelpers.getErrorMessage(ErrorType.network);
      expect(message, contains('الشبكة'));
    });

    test('should get appropriate error message for storage error', () {
      final message = ErrorHelpers.getErrorMessage(ErrorType.storage);
      expect(message, contains('التخزين'));
    });

    test('should get appropriate error message for location error', () {
      final message = ErrorHelpers.getErrorMessage(ErrorType.location);
      expect(message, contains('الموقع'));
    });

    test('should get appropriate error message for notification error', () {
      final message = ErrorHelpers.getErrorMessage(ErrorType.notification);
      expect(message, contains('الإشعارات'));
    });

    test('should get appropriate error message for audio error', () {
      final message = ErrorHelpers.getErrorMessage(ErrorType.audio);
      expect(message, contains('الصوت'));
    });

    test('should get appropriate error message for unknown error', () {
      final message = ErrorHelpers.getErrorMessage(ErrorType.unknown);
      expect(message, contains('غير متوقع'));
    });
  });
}
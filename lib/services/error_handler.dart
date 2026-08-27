import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../utils/design_system.dart';

enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

enum ErrorType {
  network,
  storage,
  location,
  notification,
  audio,
  unknown,
}

class AppError {
  final String message;
  final String? technicalDetails;
  final ErrorType type;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final StackTrace? stackTrace;
  final dynamic exception;

  AppError({
    required this.message,
    this.technicalDetails,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.stackTrace,
    this.exception,
  });

  factory AppError.fromException(
    dynamic exception, {
    ErrorType type = ErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    StackTrace? stackTrace,
  }) {
    return AppError(
      message: _getErrorMessage(exception),
      technicalDetails: exception.toString(),
      type: type,
      severity: severity,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
      exception: exception,
    );
  }

  static String _getErrorMessage(dynamic exception) {
    if (exception is Exception) {
      return exception.toString().replaceAll('Exception: ', '');
    }
    return exception.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'technicalDetails': technicalDetails,
      'type': type.name,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ErrorHandler extends ChangeNotifier {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal() {
    _init();
  }

  final List<AppError> _errors = [];
  final StreamController<AppError> _errorStreamController = StreamController<AppError>.broadcast();

  List<AppError> get errors => List.unmodifiable(_errors);
  Stream<AppError> get errorStream => _errorStreamController.stream;
  bool get hasErrors => _errors.isNotEmpty;

  void _init() {
    // Initialize Sentry if you have it configured
    // SentryFlutter.init(
    //   (options) => options.dsn = 'YOUR_SENTRY_DSN',
    // );
  }

  void handleError(
    dynamic error, {
    ErrorType type = ErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    StackTrace? stackTrace,
    bool showDialog = true,
    BuildContext? context,
  }) {
    final appError = AppError.fromException(
      error,
      type: type,
      severity: severity,
      stackTrace: stackTrace,
    );

    _addError(appError);

    // Send to Sentry if configured
    _sendToSentry(appError);

    // Show dialog if requested and context is provided
    if (showDialog && context != null) {
      _showErrorDialog(context, appError);
    }

    // Notify listeners
    notifyListeners();
  }

  void _addError(AppError error) {
    _errors.add(error);
    
    // Keep only last 100 errors
    if (_errors.length > 100) {
      _errors.removeAt(0);
    }

    _errorStreamController.add(error);
  }

  void _sendToSentry(AppError error) {
    // Send error to Sentry for monitoring
    Sentry.captureException(
      error.exception,
      stackTrace: error.stackTrace,
    );
  }

  void _showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(error: error),
    );
  }

  void clearErrors() {
    _errors.clear();
    notifyListeners();
  }

  List<AppError> getErrorsByType(ErrorType type) {
    return _errors.where((error) => error.type == type).toList();
  }

  List<AppError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errors.where((error) => error.severity == severity).toList();
  }

  @override
  void dispose() {
    _errorStreamController.close();
    super.dispose();
  }
}

class ErrorDialog extends StatelessWidget {
  final AppError error;

  const ErrorDialog({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignSystem.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
      ),
      title: Row(
        children: [
          Icon(
            _getSeverityIcon(),
            color: _getSeverityColor(),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _getSeverityTitle(),
            style: const TextStyle(
              color: DesignSystem.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error.message,
            style: const TextStyle(
              color: DesignSystem.textSecondary,
              fontSize: 14,
            ),
          ),
          if (error.technicalDetails != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text(
                'Technical Details',
                style: TextStyle(
                  color: DesignSystem.textMuted,
                  fontSize: 12,
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignSystem.bgDarkest,
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                  ),
                  child: SelectableText(
                    error.technicalDetails!,
                    style: const TextStyle(
                      color: DesignSystem.textMuted,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'OK',
            style: TextStyle(
              color: DesignSystem.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getSeverityIcon() {
    switch (error.severity) {
      case ErrorSeverity.low:
        return Icons.info_outline_rounded;
      case ErrorSeverity.medium:
        return Icons.warning_amber_rounded;
      case ErrorSeverity.high:
        return Icons.error_outline_rounded;
      case ErrorSeverity.critical:
        return Icons.dangerous_rounded;
    }
  }

  Color _getSeverityColor() {
    switch (error.severity) {
      case ErrorSeverity.low:
        return DesignSystem.info;
      case ErrorSeverity.medium:
        return DesignSystem.warning;
      case ErrorSeverity.high:
        return DesignSystem.error;
      case ErrorSeverity.critical:
        return DesignSystem.error;
    }
  }

  String _getSeverityTitle() {
    switch (error.severity) {
      case ErrorSeverity.low:
        return 'معلومة';
      case ErrorSeverity.medium:
        return 'تنبيه';
      case ErrorSeverity.high:
        return 'خطأ';
      case ErrorSeverity.critical:
        return 'خطأ حرج';
    }
  }
}

// Helper functions for common error scenarios
class ErrorHelpers {
  static void handleNetworkError(
    dynamic error, {
    BuildContext? context,
    StackTrace? stackTrace,
  }) {
    ErrorHandler().handleError(
      error,
      type: ErrorType.network,
      severity: ErrorSeverity.medium,
      stackTrace: stackTrace,
      context: context,
    );
  }

  static void handleStorageError(
    dynamic error, {
    BuildContext? context,
    StackTrace? stackTrace,
  }) {
    ErrorHandler().handleError(
      error,
      type: ErrorType.storage,
      severity: ErrorSeverity.high,
      stackTrace: stackTrace,
      context: context,
    );
  }

  static void handleLocationError(
    dynamic error, {
    BuildContext? context,
    StackTrace? stackTrace,
  }) {
    ErrorHandler().handleError(
      error,
      type: ErrorType.location,
      severity: ErrorSeverity.medium,
      stackTrace: stackTrace,
      context: context,
    );
  }

  static void handleNotificationError(
    dynamic error, {
    BuildContext? context,
    StackTrace? stackTrace,
  }) {
    ErrorHandler().handleError(
      error,
      type: ErrorType.notification,
      severity: ErrorSeverity.low,
      stackTrace: stackTrace,
      context: context,
    );
  }

  static void handleAudioError(
    dynamic error, {
    BuildContext? context,
    StackTrace? stackTrace,
  }) {
    ErrorHandler().handleError(
      error,
      type: ErrorType.audio,
      severity: ErrorSeverity.medium,
      stackTrace: stackTrace,
      context: context,
    );
  }

  static String getErrorMessage(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'خطأ في الاتصال بالشبكة. يرجى التحقق من اتصال الإنترنت.';
      case ErrorType.storage:
        return 'خطأ في الوصول إلى التخزين المحلي.';
      case ErrorType.location:
        return 'خطأ في تحديد الموقع. يرجى التحقق من إعدادات الموقع.';
      case ErrorType.notification:
        return 'خطأ في إرسال الإشعارات.';
      case ErrorType.audio:
        return 'خطأ في تشغيل الصوت.';
      case ErrorType.unknown:
        return 'حدث خطأ غير متوقع.';
    }
  }
}
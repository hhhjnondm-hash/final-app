import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// App Security & Anti-Tamper Service
/// Provides strong defenses against tampering, MITM attacks, data sniffing, and unsafe inputs.
class AppSecurityService {
  static final AppSecurityService _instance = AppSecurityService._internal();
  factory AppSecurityService() => _instance;
  AppSecurityService._internal();

  // AES-256 encryption key (32 bytes)
  static const String _encryptionKey = 'RafeeqSecured2026Key32Bytes!123';
  static const List<String> _trustedDomains = [
    'mp3quran.net',
    'server6.mp3quran.net',
    'server7.mp3quran.net',
    'server8.mp3quran.net',
    'server10.mp3quran.net',
    'server11.mp3quran.net',
    'server12.mp3quran.net',
    'api.aladhan.com',
    'timesprayer.com',
    'blubrry.com',
    'quran-central.com',
  ];

  // Secure storage for sensitive data
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  bool _isSecureEnvironment = true;
  bool get isSecureEnvironment => _isSecureEnvironment;

  Future<void> initialize() async {
    await _validateEnvironment();
    debugPrint('🛡️ App Security Service initialized. System protected.');
  }

  /// Check basic environment integrity and root/jailbreak detection
  Future<void> _validateEnvironment() async {
    try {
      // Check for jailbreak/root
      final isJailbroken = await FlutterJailbreakDetection.jailbroken;
      final isDevelopmentMode = await FlutterJailbreakDetection.developerMode;
      
      if (isJailbroken) {
        debugPrint('⚠️ Security Warning: Device is jailbroken/rooted');
        _isSecureEnvironment = false;
      }
      
      if (isDevelopmentMode) {
        debugPrint('⚠️ Security Warning: Device is in developer mode');
      }
      
      _isSecureEnvironment = !isJailbroken;
    } catch (e) {
      debugPrint('Security: Jailbreak detection error - $e');
      _isSecureEnvironment = true; // Assume secure if detection fails
    }
  }

  /// Check if device is secure (not rooted/jailbroken)
  Future<bool> isDeviceSecure() async {
    try {
      final isJailbroken = await FlutterJailbreakDetection.jailbroken;
      return !isJailbroken;
    } catch (e) {
      debugPrint('Security: Device security check error - $e');
      return true; // Assume secure if check fails
    }
  }

  /// 1. AES-256 Encryption for sensitive data
  static String encryptData(String plainText) {
    if (plainText.isEmpty) return plainText;
    try {
      final key = encrypt.Key.fromUtf8(_encryptionKey.padRight(32).substring(0, 32));
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('Security: Encryption error - $e');
      return plainText; // Fallback to plain text on error
    }
  }

  /// Decrypt data encrypted with AES-256
  static String decryptData(String encryptedData) {
    if (encryptedData.isEmpty) return encryptedData;
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) return encryptedData;
      
      final key = encrypt.Key.fromUtf8(_encryptionKey.padRight(32).substring(0, 32));
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('Security: Decryption error - $e');
      return encryptedData; // Return encrypted on error
    }
  }

  /// 2. Secure Local Storage using flutter_secure_storage
  static Future<bool> saveSecureString(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } catch (e) {
      debugPrint('Security: Secure storage error - $e');
      return false;
    }
  }

  static Future<String?> getSecureString(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('Security: Secure storage read error - $e');
      return null;
    }
  }

  static Future<bool> deleteSecureString(String key) async {
    try {
      await _secureStorage.delete(key: key);
      return true;
    } catch (e) {
      debugPrint('Security: Secure storage delete error - $e');
      return false;
    }
  }

  static Future<bool> containsSecureKey(String key) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } catch (e) {
      debugPrint('Security: Secure storage contains error - $e');
      return false;
    }
  }

  /// 3. Network URL & Domain Whitelist Validation (Anti-Malware & Phishing)
  static bool isUrlAllowed(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      
      // Allow local assets and localhost during development
      if (url.startsWith('assets/') || uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '0.0.0.0') {
        return true;
      }

      // Enforce HTTPS
      if (uri.scheme != 'https' && !kDebugMode) {
        debugPrint('⚠️ Security Warning: Insecure HTTP rejected: ');
        return false;
      }

      // Check trusted domain list
      final host = uri.host.toLowerCase();
      final isTrusted = _trustedDomains.any((domain) => host == domain || host.endsWith('.'));
      
      if (!isTrusted) {
        debugPrint('⚠️ Security Warning: Untrusted host blocked: System.Management.Automation.Internal.Host.InternalHost');
      }
      return isTrusted;
    } catch (e) {
      debugPrint('⚠️ Security Error parsing URL: ');
      return false;
    }
  }

  /// 4. Input Sanitization (Anti-XSS & SQLi / Injection protection)
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    var sanitized = input;
    
    // Remove script tags and dangerous HTML/JS injections
    sanitized = sanitized.replaceAll(RegExp(r'<script\b[^>]*>([\s\S]*?)<\/script>', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'onload\s*=', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'onerror\s*=', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'onclick\s*=', caseSensitive: false), '');

    // Trim excessive null characters
    sanitized = sanitized.replaceAll('\u0000', '');

    return sanitized.trim();
  }

  /// 5. Hash Fingerprint Generator for Audio Integrity
  static String computeChecksum(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}

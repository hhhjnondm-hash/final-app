import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/prayer_models.dart';
import 'storage_service.dart';

class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal() {
    _init();
  }

  final StorageService _storage = StorageService();
  Position? _currentPosition;
  LocationProfile? _currentLocation;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStreamSubscription;

  Position? get currentPosition => _currentPosition;
  LocationProfile? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLocation => _currentLocation != null;

  Future<void> _init() async {
    await _storage.init();
    await _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final savedLocation = await _storage.getLocation();
    if (savedLocation != null) {
      _currentLocation = LocationProfile(
        cityName: savedLocation['cityName'] as String,
        countryName: savedLocation['countryName'] as String,
        latitude: savedLocation['latitude'] as double,
        longitude: savedLocation['longitude'] as double,
        qiblaAngle: savedLocation['qiblaAngle'] as double,
      );
      notifyListeners();
    }
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check and request location permissions
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current position
  Future<Position> getCurrentPosition() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if location service is enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'خدمات الموقع غير مفعلة. يرجى تفعيلها في إعدادات الجهاز.';
        _isLoading = false;
        notifyListeners();
        throw LocationServiceDisabledException();
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'تم رفض إذن الموقع. يرجى منح الإذن للوصول إلى الموقع.';
          _isLoading = false;
          notifyListeners();
          throw LocationPermissionDeniedException();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'تم رفض إذن الموقع نهائياً. يرجى تفعيله في إعدادات الجهاز.';
        _isLoading = false;
        notifyListeners();
        throw LocationPermissionDeniedForeverException();
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get location name using reverse geocoding (simplified)
      final locationName = await _getLocationName(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Calculate Qibla angle
      final qiblaAngle = _calculateQiblaAngle(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      _currentLocation = LocationProfile(
        cityName: locationName['city'] ?? 'موقعك الحالي',
        countryName: locationName['country'] ?? '',
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        qiblaAngle: qiblaAngle,
      );

      // Save to storage
      await _storage.saveLocation(
        cityName: _currentLocation!.cityName,
        countryName: _currentLocation!.countryName,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        qiblaAngle: _currentLocation!.qiblaAngle,
      );

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return _currentPosition!;
    } catch (e) {
      _isLoading = false;
      if (e is! LocationServiceDisabledException && 
          e is! LocationPermissionDeniedException && 
          e is! LocationPermissionDeniedForeverException) {
        _errorMessage = 'خطأ في تحديد الموقع: ${e.toString()}';
      }
      notifyListeners();
      rethrow;
    }
  }

  // Start continuous location updates
  void startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Update every 100 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _currentPosition = position;
      // Update location info (you might want to debounce this)
      _updateLocationFromPosition(position);
    });
  }

  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> _updateLocationFromPosition(Position position) async {
    final locationName = await _getLocationName(position.latitude, position.longitude);
    final qiblaAngle = _calculateQiblaAngle(position.latitude, position.longitude);

    _currentLocation = LocationProfile(
      cityName: locationName['city'] ?? 'موقعك الحالي',
      countryName: locationName['country'] ?? '',
      latitude: position.latitude,
      longitude: position.longitude,
      qiblaAngle: qiblaAngle,
    );

    await _storage.saveLocation(
      cityName: _currentLocation!.cityName,
      countryName: _currentLocation!.countryName,
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      qiblaAngle: _currentLocation!.qiblaAngle,
    );

    notifyListeners();
  }

  // Calculate distance between two points in meters
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Calculate distance to Kaaba
  double calculateDistanceToKaaba() {
    if (_currentLocation == null) return 0.0;
    
    const double kaabaLat = 21.4225;
    const double kaabaLng = 39.8262;
    
    return calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      kaabaLat,
      kaabaLng,
    );
  }

  // Calculate Qibla bearing
  double _calculateQiblaAngle(double latitude, double longitude) {
    const double kaabaLat = 21.4225;
    const double kaabaLng = 39.8262;

    final lat1 = latitude * (3.14159265359 / 180.0);
    final lat2 = kaabaLat * (3.14159265359 / 180.0);
    final lng1 = longitude * (3.14159265359 / 180.0);
    final lng2 = kaabaLng * (3.14159265359 / 180.0);

    final y = math.sin(lng2 - lng1);
    final x = math.cos(lat1) * math.tan(lat2) - math.sin(lat1) * math.cos(lng2 - lng1);
    
    final qibla = math.atan2(y, x) * (180.0 / 3.14159265359);
    return (qibla + 360) % 360;
  }

  // Get location name (simplified - in production use geocoding package)
  Future<Map<String, String>> _getLocationName(double latitude, double longitude) async {
    // This is a simplified version. In production, use the 'geocoding' package
    // For now, return approximate location based on coordinates
    
    // Egypt
    if (latitude >= 22 && latitude <= 32 && longitude >= 25 && longitude <= 35) {
      if (latitude >= 29.5 && latitude <= 30.5 && longitude >= 30.5 && longitude <= 32.0) {
        return {'city': 'القاهرة', 'country': 'مصر'};
      }
      if (latitude >= 30.5 && latitude <= 32.0 && longitude >= 28.5 && longitude <= 30.0) {
        return {'city': 'الإسكندرية', 'country': 'مصر'};
      }
      return {'city': 'مصر', 'country': 'مصر'};
    }
    
    // Saudi Arabia
    if (latitude >= 16 && latitude <= 32 && longitude >= 34 && longitude <= 55) {
      if (latitude >= 21.0 && latitude <= 22.0 && longitude >= 39.5 && longitude <= 40.0) {
        return {'city': 'مكة المكرمة', 'country': 'السعودية'};
      }
      if (latitude >= 24.0 && latitude <= 25.0 && longitude >= 39.0 && longitude <= 40.0) {
        return {'city': 'المدينة المنورة', 'country': 'السعودية'};
      }
      if (latitude >= 24.0 && latitude <= 25.5 && longitude >= 46.0 && longitude <= 47.5) {
        return {'city': 'الرياض', 'country': 'السعودية'};
      }
      return {'city': 'السعودية', 'country': 'السعودية'};
    }
    
    // UAE
    if (latitude >= 22 && latitude <= 26 && longitude >= 51 && longitude <= 56) {
      if (latitude >= 24.5 && latitude <= 26.0 && longitude >= 54.5 && longitude <= 56.0) {
        return {'city': 'دبي', 'country': 'الإمارات'};
      }
      return {'city': 'الإمارات', 'country': 'الإمارات'};
    }
    
    // Palestine
    if (latitude >= 31 && latitude <= 33 && longitude >= 34 && longitude <= 36) {
      if (latitude >= 31.5 && latitude <= 32.0 && longitude >= 35.0 && longitude <= 35.5) {
        return {'city': 'القدس', 'country': 'فلسطين'};
      }
      return {'city': 'فلسطين', 'country': 'فلسطين'};
    }
    
    return {'city': 'موقعك الحالي', 'country': ''};
  }

  // Manually set location (fallback option)
  Future<void> setManualLocation(LocationProfile location) async {
    _currentLocation = location;
    await _storage.saveLocation(
      cityName: location.cityName,
      countryName: location.countryName,
      latitude: location.latitude,
      longitude: location.longitude,
      qiblaAngle: location.qiblaAngle,
    );
    notifyListeners();
  }

  // Open app settings for location
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}

// Custom exceptions
class LocationServiceDisabledException implements Exception {
  final String message = 'خدمات الموقع غير مفعلة';
  @override
  String toString() => message;
}

class LocationPermissionDeniedException implements Exception {
  final String message = 'تم رفض إذن الموقع';
  @override
  String toString() => message;
}

class LocationPermissionDeniedForeverException implements Exception {
  final String message = 'تم رفض إذن الموقع نهائياً';
  @override
  String toString() => message;
}
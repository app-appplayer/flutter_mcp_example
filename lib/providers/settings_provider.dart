import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../services/secure_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  late AppSettings _settings;
  bool _isLoading = false;
  String? _errorMessage;

  // API Key visibility control
  final Map<String, bool> _showApiKeys = {};

  // Getters
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor
  SettingsProvider() {
    _settings = AppSettings();
    _initializeSettings();
  }

  // Initialize settings
  Future<void> _initializeSettings() async {
    _setLoading(true);

    try {
      // Load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final settingsStr = prefs.getString('app_settings');

      if (settingsStr != null) {
        try {
          final Map<String, dynamic> settingsMap = jsonDecode(settingsStr);
          _settings = AppSettings.fromJson(settingsMap);
        } catch (e) {
          _setError('Failed to parse saved settings: $e');
          // Continue with default settings
        }
      }

      // Initialize show API keys states
      for (final provider in _settings.providerList) {
        _showApiKeys[provider] = false;
      }
    } catch (e) {
      _setError('Failed to load settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Save settings
  Future<void> saveSettings() async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_settings', jsonEncode(_settings.toJson()));
    } catch (e) {
      _setError('Failed to save settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update settings
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await saveSettings();
    notifyListeners();
  }

  // Update theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _settings = _settings.copyWith(themeMode: themeMode);
    await saveSettings();
    notifyListeners();
  }

  // Toggle performance monitoring
  Future<void> togglePerformanceMonitoring(bool value) async {
    _settings = _settings.copyWith(enablePerformanceMonitoring: value);
    await saveSettings();
    notifyListeners();
  }

  // Set memory threshold
  Future<void> setMemoryThreshold(int threshold) async {
    _settings = _settings.copyWith(highMemoryThresholdMB: threshold);
    await saveSettings();
    notifyListeners();
  }

  // Toggle background service
  Future<void> toggleBackgroundService(bool value) async {
    _settings = _settings.copyWith(useBackgroundService: value);
    await saveSettings();
    notifyListeners();
  }

  // Toggle system tray
  Future<void> toggleSystemTray(bool value) async {
    _settings = _settings.copyWith(showSystemTray: value);
    await saveSettings();
    notifyListeners();
  }

  // Toggle logging
  Future<void> toggleLogging(bool value) async {
    _settings = _settings.copyWith(enableLogging: value);
    await saveSettings();
    notifyListeners();
  }

  // Toggle message cache
  Future<void> toggleMessageCache(bool value) async {
    _settings = _settings.copyWith(useMessageCache: value);
    await saveSettings();
    notifyListeners();
  }

  // Save API key
  Future<void> saveApiKey(String provider, String apiKey) async {
    try {
      await SecureStorageService.saveApiKey(provider, apiKey);
      notifyListeners();
    } catch (e) {
      _setError('Failed to save API key: $e');
    }
  }

  // Get API key
  Future<String?> getApiKey(String provider) async {
    try {
      return await SecureStorageService.getApiKey(provider);
    } catch (e) {
      _setError('Failed to retrieve API key: $e');
      return null;
    }
  }

  // Delete API key
  Future<void> deleteApiKey(String provider) async {
    try {
      await SecureStorageService.deleteApiKey(provider);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete API key: $e');
    }
  }

  // Toggle API key visibility
  void toggleApiKeyVisibility(String provider) {
    _showApiKeys[provider] = !(_showApiKeys[provider] ?? false);
    notifyListeners();
  }

  // Get API key visibility
  bool isApiKeyVisible(String provider) {
    return _showApiKeys[provider] ?? false;
  }

  // Reset to default settings
  Future<void> resetToDefaults() async {
    _settings = AppSettings();
    await saveSettings();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
}
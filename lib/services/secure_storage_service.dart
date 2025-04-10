/*
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SecureStorageService {
  // API Keys
  static const String _openaiKeyKey = 'api_key_openai';
  static const String _claudeKeyKey = 'api_key_claude';
  static const String _togetherKeyKey = 'api_key_together';

  // Saved connections
  static const String _savedConnectionsKey = 'saved_connections';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Save API key for provider
  static Future<void> saveApiKey(String provider, String apiKey) async {
    final prefs = await _prefs;
    String key = _getApiKeyName(provider);
    print('Saving API key for $provider with key: $key');
    await prefs.setString(key, apiKey);
  }

  // Get API key for provider
  static Future<String?> getApiKey(String provider) async {
    final prefs = await _prefs;
    String key = _getApiKeyName(provider);
    final value = prefs.getString(key);
    print('Retrieved API key for $provider from key $key: ${value != null ? "found (length: ${value.length})" : "not found"}');
    return value;
  }

  // Delete API key for provider
  static Future<void> deleteApiKey(String provider) async {
    final prefs = await _prefs;
    String key = _getApiKeyName(provider);
    await prefs.remove(key);
  }

  static String _getApiKeyName(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return _openaiKeyKey;
      case 'claude':
        return _claudeKeyKey;
      case 'together':
        return _togetherKeyKey;
      default:
        return 'api_key_${provider.toLowerCase()}';
    }
  }

  // Save named connections list
  static Future<void> saveConnectionNames(List<String> names) async {
    final prefs = await _prefs;
    final jsonStr = jsonEncode(names);
    await prefs.setString(_savedConnectionsKey, jsonStr);
  }

  // Get saved connection names
  static Future<List<String>> getConnectionNames() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(_savedConnectionsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => item.toString()).toList();
    } catch (e) {
      print('Error parsing connection names: $e');
      return [];
    }
  }

  // Save connection config
  static Future<void> saveConnectionConfig(String name, Map<String, dynamic> config) async {
    final prefs = await _prefs;
    final jsonStr = jsonEncode(config);
    await prefs.setString('connection_$name', jsonStr);

    // Update the list of connection names
    final names = await getConnectionNames();
    if (!names.contains(name)) {
      names.add(name);
      await saveConnectionNames(names);
    }
  }

  // Get connection config
  static Future<Map<String, dynamic>?> getConnectionConfig(String name) async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString('connection_$name');
    if (jsonStr == null || jsonStr.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing connection config: $e');
      return null;
    }
  }

  // Delete connection config
  static Future<void> deleteConnectionConfig(String name) async {
    final prefs = await _prefs;
    await prefs.remove('connection_$name');

    // Update the list of connection names
    final names = await getConnectionNames();
    if (names.contains(name)) {
      names.remove(name);
      await saveConnectionNames(names);
    }
  }

  // Debug method to get all keys
  static Future<List<String>> getAllKeys() async {
    final prefs = await _prefs;
    return prefs.getKeys().toList();
  }

  // Save generic value
  static Future<void> saveSecureValue(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  // Get generic value
  static Future<String?> getSecureValue(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  // Delete generic value
  static Future<void> deleteSecureValue(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  // Check if key exists
  static Future<bool> hasKey(String key) async {
    final prefs = await _prefs;
    return prefs.containsKey(key);
  }
}
*/

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // API Keys
  static const String _openaiKeyKey = 'api_key_openai';
  static const String _claudeKeyKey = 'api_key_claude';
  static const String _togetherKeyKey = 'api_key_together';

  // Saved connections
  static const String _savedConnectionsKey = 'saved_connections';

  // Save API key for provider
  static Future<void> saveApiKey(String provider, String apiKey) async {
    String key;
    switch (provider.toLowerCase()) {
      case 'openai':
        key = _openaiKeyKey;
        break;
      case 'claude':
        key = _claudeKeyKey;
        break;
      case 'together':
        key = _togetherKeyKey;
        break;
      default:
        key = 'api_key_${provider.toLowerCase()}';
    }

    print('Retrieved API keyName: $key');
    await _storage.write(key: key, value: apiKey);
  }

  // Get API key for provider
  static Future<String?> getApiKey(String provider) async {
    String key;
    switch (provider.toLowerCase()) {
      case 'openai':
        key = _openaiKeyKey;
        break;
      case 'claude':
        key = _claudeKeyKey;
        break;
      case 'together':
        key = _togetherKeyKey;
        break;
      default:
        key = 'api_key_${provider.toLowerCase()}';
    }

    final value = await _storage.read(key: key);
    print('Retrieved API key for $provider from key $key: ${value != null ? "found (length: ${value.length})" : "not found"}');
    return value;
  }

  // Delete API key for provider
  static Future<void> deleteApiKey(String provider) async {
    String key;
    switch (provider.toLowerCase()) {
      case 'openai':
        key = _openaiKeyKey;
        break;
      case 'claude':
        key = _claudeKeyKey;
        break;
      case 'together':
        key = _togetherKeyKey;
        break;
      default:
        key = 'api_key_${provider.toLowerCase()}';
    }

    await _storage.delete(key: key);
  }

  // Save named connections list
  static Future<void> saveConnectionNames(List<String> names) async {
    final jsonStr = jsonEncode(names);
    await _storage.write(key: _savedConnectionsKey, value: jsonStr);
  }

  // Get saved connection names
  static Future<List<String>> getConnectionNames() async {
    final jsonStr = await _storage.read(key: _savedConnectionsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => item.toString()).toList();
    } catch (e) {
      print('Error parsing connection names: $e');
      return [];
    }
  }

  // Save connection config
  static Future<void> saveConnectionConfig(String name, Map<String, dynamic> config) async {
    final jsonStr = jsonEncode(config);
    await _storage.write(key: 'connection_$name', value: jsonStr);

    // Update the list of connection names
    final names = await getConnectionNames();
    if (!names.contains(name)) {
      names.add(name);
      await saveConnectionNames(names);
    }
  }

  // Get connection config
  static Future<Map<String, dynamic>?> getConnectionConfig(String name) async {
    final jsonStr = await _storage.read(key: 'connection_$name');
    if (jsonStr == null || jsonStr.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing connection config: $e');
      return null;
    }
  }

  // Delete connection config
  static Future<void> deleteConnectionConfig(String name) async {
    await _storage.delete(key: 'connection_$name');

    // Update the list of connection names
    final names = await getConnectionNames();
    if (names.contains(name)) {
      names.remove(name);
      await saveConnectionNames(names);
    }
  }

  // Debug method to get all keys in storage
  static Future<List<String>> getAllKeys() async {
    // This is only available on some platforms
    try {
      final all = await _storage.readAll();
      return all.keys.toList();
    } catch (e) {
      print('Error getting all keys: $e');
      return [];
    }
  }

  // Save generic secure value
  static Future<void> saveSecureValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Get generic secure value
  static Future<String?> getSecureValue(String key) async {
    return await _storage.read(key: key);
  }

  // Delete generic secure value
  static Future<void> deleteSecureValue(String key) async {
    await _storage.delete(key: key);
  }

  // Check if key exists
  static Future<bool> hasKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }
}

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
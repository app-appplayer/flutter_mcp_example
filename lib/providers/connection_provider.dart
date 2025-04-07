import 'package:flutter/material.dart';
import '../models/connection_config.dart';
import '../services/mcp_client_service.dart';
import '../services/secure_storage_service.dart';

class ConnectionProvider extends ChangeNotifier {
  final McpClientService _mcpService = McpClientService();

  ConnectionConfig? _currentConfig;
  List<String> _savedConnections = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  ConnectionConfig? get currentConfig => _currentConfig;
  List<String> get savedConnections => List.unmodifiable(_savedConnections);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ConnectionStatus get connectionStatus => _mcpService.status;
  bool get isConnected => _mcpService.isConnected;
  String? get clientId => _mcpService.clientId;
  String? get llmId => _mcpService.llmId;

  // Initialize
  Future<void> initialize() async {
    _setLoading(true);

    try {
      // Load saved connections
      await _loadSavedConnections();

      // Initialize with default if no connections
      if (_savedConnections.isEmpty) {
        final defaultConfig = ConnectionConfig.defaultConfig();
        await saveConnection(defaultConfig);
        _currentConfig = defaultConfig;
      } else {
        // Load the first saved connection
        await loadConnection(_savedConnections.first);
      }
    } catch (e) {
      _setError('Initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load saved connections from secure storage
  Future<void> _loadSavedConnections() async {
    try {
      _savedConnections = await SecureStorageService.getConnectionNames();
    } catch (e) {
      _setError('Failed to load saved connections: $e');
      _savedConnections = [];
    }
  }

  // Load a specific connection
  Future<void> loadConnection(String name) async {
    _setLoading(true);

    try {
      final configJson = await SecureStorageService.getConnectionConfig(name);
      if (configJson != null) {
        _currentConfig = ConnectionConfig.fromJson(configJson);
        notifyListeners();
      } else {
        _setError('Connection "$name" not found');
      }
    } catch (e) {
      _setError('Failed to load connection: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Save a connection
  Future<void> saveConnection(ConnectionConfig config) async {
    _setLoading(true);

    try {
      await SecureStorageService.saveConnectionConfig(
        config.name,
        config.toJson(),
      );

      _currentConfig = config;

      // Refresh the list of saved connections
      await _loadSavedConnections();
    } catch (e) {
      _setError('Failed to save connection: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a connection
  Future<void> deleteConnection(String name) async {
    _setLoading(true);

    try {
      await SecureStorageService.deleteConnectionConfig(name);

      // If deleting the current connection, reset current
      if (_currentConfig?.name == name) {
        _currentConfig = null;
      }

      // Refresh the list of saved connections
      await _loadSavedConnections();

      // If no connections left, create a default one
      if (_savedConnections.isEmpty) {
        final defaultConfig = ConnectionConfig.defaultConfig();
        await saveConnection(defaultConfig);
        _currentConfig = defaultConfig;
      } else if (_currentConfig == null) {
        // Load the first saved connection
        await loadConnection(_savedConnections.first);
      }
    } catch (e) {
      _setError('Failed to delete connection: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Connect to MCP server
  Future<bool> connect() async {
    if (_currentConfig == null) {
      _setError('No connection configuration');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final result = await _mcpService.connect(_currentConfig!);
      if (!result) {
        _setError(_mcpService.errorMessage ?? 'Connection failed');
      }
      notifyListeners();
      return result;
    } catch (e) {
      _setError('Connection error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Disconnect from MCP server
  Future<void> disconnect() async {
    _setLoading(true);

    try {
      await _mcpService.disconnect();
      notifyListeners();
    } catch (e) {
      _setError('Disconnect error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get MCP client service
  McpClientService getMcpService() {
    return _mcpService;
  }

  // Helper for setting loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper for setting error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
}
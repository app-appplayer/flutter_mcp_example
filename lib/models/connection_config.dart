import 'package:flutter_mcp/flutter_mcp.dart';

/// Connection configuration for MCP client
class ConnectionConfig {
  final String name;
  final String clientName;
  final String clientVersion;
  final String? transportCommand;
  final List<String>? transportArgs;
  final String? serverUrl;
  final bool useSSE;
  final ClientCapabilities? capabilities;
  final String? llmProvider;
  final String? modelName;

  ConnectionConfig({
    required this.name,
    required this.clientName,
    required this.clientVersion,
    this.transportCommand,
    this.transportArgs,
    this.serverUrl,
    this.useSSE = false,
    this.capabilities,
    this.llmProvider,
    this.modelName,
  });

  // Copy with method
  ConnectionConfig copyWith({
    String? name,
    String? clientName,
    String? clientVersion,
    String? transportCommand,
    List<String>? transportArgs,
    String? serverUrl,
    bool? useSSE,
    ClientCapabilities? capabilities,
    String? llmProvider,
    String? modelName,
  }) {
    return ConnectionConfig(
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      clientVersion: clientVersion ?? this.clientVersion,
      transportCommand: transportCommand ?? this.transportCommand,
      transportArgs: transportArgs ?? this.transportArgs,
      serverUrl: serverUrl ?? this.serverUrl,
      useSSE: useSSE ?? this.useSSE,
      capabilities: capabilities ?? this.capabilities,
      llmProvider: llmProvider ?? this.llmProvider,
      modelName: modelName ?? this.modelName,
    );
  }

  // To JSON method
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'clientName': clientName,
      'clientVersion': clientVersion,
      'transportCommand': transportCommand,
      'transportArgs': transportArgs,
      'serverUrl': serverUrl,
      'useSSE': useSSE,
      'capabilities': {
        'roots': capabilities?.roots ?? false,
        'rootsListChanged': capabilities?.rootsListChanged ?? false,
        'sampling': capabilities?.sampling ?? false,
      },
      'llmProvider': llmProvider,
      'modelName': modelName,
    };
  }

  // From JSON factory
  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    return ConnectionConfig(
      name: json['name'] as String,
      clientName: json['clientName'] as String,
      clientVersion: json['clientVersion'] as String,
      transportCommand: json['transportCommand'] as String?,
      transportArgs: json['transportArgs'] != null
          ? List<String>.from(json['transportArgs'])
          : null,
      serverUrl: json['serverUrl'] as String?,
      useSSE: json['useSSE'] as bool? ?? false,
      capabilities: json['capabilities'] != null
          ? ClientCapabilities(
        roots: json['capabilities']['roots'] as bool? ?? false,
        rootsListChanged: json['capabilities']['rootsListChanged'] as bool? ?? false,
        sampling: json['capabilities']['sampling'] as bool? ?? false,
      )
          : null,
      llmProvider: json['llmProvider'] as String?,
      modelName: json['modelName'] as String?,
    );
  }

  // Default configuration
  factory ConnectionConfig.defaultConfig() {
    return ConnectionConfig(
      name: 'Default Connection',
      clientName: 'MCP Test Client',
      clientVersion: '1.0.0',
      transportCommand: null,
      transportArgs: null,
      serverUrl: 'http://localhost:8080/sse',
      useSSE: true,
      capabilities: ClientCapabilities(
        roots: true,
        rootsListChanged: true,
        sampling: true,
      ),
      llmProvider: 'openai',
      modelName: 'gpt-4',
    );
  }

  // Validation method
  String? validate() {
    if (useSSE && (serverUrl == null || serverUrl!.isEmpty)) {
      return 'Server URL must be provided when using SSE transport';
    }

    if (!useSSE && (transportCommand == null || transportCommand!.isEmpty)) {
      return 'Transport command must be provided when using stdio transport';
    }

    return null;
  }
}
import 'package:flutter_mcp/flutter_mcp.dart';
import '../models/connection_config.dart';
import '../models/chat_message.dart' as app;
import '../models/app_settings.dart';
import 'secure_storage_service.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class McpClientService {
  // Flutter MCP instance
  final FlutterMCP _mcp = FlutterMCP.instance;

  // Client status
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorMessage;

  // Connection information
  String? _clientId;
  String? _llmId;
  ConnectionConfig? _config;

  // Tool information
  List<Tool>? _availableTools;

  // Status getters
  ConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == ConnectionStatus.connected;
  String? get clientId => _clientId;
  String? get llmId => _llmId;
  List<Tool>? get availableTools => _availableTools;
  ConnectionConfig? get currentConfig => _config;

  // Initialize the MCP service
  Future<void> initialize(AppSettings settings) async {
    try {
      await _mcp.init(MCPConfig(
        appName: 'MCP Test Client',
        appVersion: '1.0.0',
        useBackgroundService: settings.useBackgroundService,
        useNotification: true,
        useTray: settings.showSystemTray,
        secure: true,
        lifecycleManaged: true,
        autoStart: false,
        //loggingLevel: settings.enableLogging ? LogLevel.debug : LogLevel.info,
        loggingLevel: LogLevel.debug,
        enablePerformanceMonitoring: settings.enablePerformanceMonitoring,
        highMemoryThresholdMB: settings.highMemoryThresholdMB,
      ));
    } catch (e) {
      _errorMessage = 'Failed to initialize MCP: $e';
      _status = ConnectionStatus.error;
      rethrow;
    }
  }

  // Connect to the MCP server
  Future<bool> connect(ConnectionConfig config) async {
    _config = config;
    _status = ConnectionStatus.connecting;
    _errorMessage = null;

    try {
      // 1. Create the client
      _clientId = await _mcp.createClient(
        name: config.clientName,
        version: config.clientVersion,
        transportCommand: config.useSSE ? null : config.transportCommand,
        transportArgs: config.useSSE ? null : config.transportArgs,
        serverUrl: config.useSSE ? config.serverUrl : null,
        authToken: config.authToken, // Added auth token
        capabilities: config.capabilities,
      );

      // 2. If LLM provider/model is configured, create LLM
      if (config.llmProvider != null && config.modelName != null) {
        // Get API key from secure storage
        final apiKey = await SecureStorageService.getApiKey(config.llmProvider!);
        print('Connecting with LLM provider: ${config.llmProvider}, API key: ${apiKey != null ? "found (length: ${apiKey.length})" : "null"}');

        if (apiKey != null && apiKey.isNotEmpty) {
          // Create LLM client
          _llmId = await _mcp.createLlm(
            providerName: config.llmProvider!,
            config: LlmConfiguration(
              apiKey: apiKey,
              model: config.modelName!,
              retryOnFailure: true,
              maxRetries: 3,
            ),
          );

          // Integrate client with LLM
          await _mcp.integrateClientWithLlm(
            clientId: _clientId!,
            llmId: _llmId!,
          );
        }
      } else {
        _errorMessage = 'API key not found for provider: ${config.llmProvider}';
        _status = ConnectionStatus.error;
        return false;
      }

      // 3. Connect the client
      await _mcp.connectClient(_clientId!);

      // 4. Retrieve available tools
      _availableTools = await getAvailableTools();

      _status = ConnectionStatus.connected;
      return true;
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _status = ConnectionStatus.error;

      // Clean up if error occurs
      if (_clientId != null) {
        try {
          await disconnect();
        } catch (_) {
          // Ignore cleanup errors
        }
      }

      return false;
    }
  }

  // Disconnect
  Future<void> disconnect() async {
    if (_clientId == null) return;

    try {
      await _mcp.shutdown();
      _status = ConnectionStatus.disconnected;
      _clientId = null;
      _llmId = null;
      _availableTools = null;
    } catch (e) {
      _errorMessage = 'Disconnect error: $e';
      _status = ConnectionStatus.error;
      rethrow;
    }
  }

  // Get available tools
  Future<List<Tool>> getAvailableTools() async {
    if (_clientId == null || !isConnected) {
      return [];
    }

    try {
      final client = _mcp.getClient(_clientId!);
      if (client == null) return [];

      return await client.listTools() as List<Tool>;
    } catch (e) {
      _errorMessage = 'Error retrieving tools: $e';
      return [];
    }
  }

  // Call a tool
  Future<app.ChatMessage> callTool(String toolName, Map<String, dynamic> arguments) async {
    if (_clientId == null || !isConnected) {
      throw Exception('Client not connected');
    }

    try {
      final result = await _mcp.callTool(_clientId!, toolName, arguments);

      // Create tool response message
      String resultText = 'No result returned';

      // Process the content if available
      if (result.content.isNotEmpty) {
        // Get first content item (typically used for tool results)
        final firstContent = result.content.first;

        // Extract text from various content types
        if (firstContent is TextContent) {
          resultText = (firstContent as TextContent).text;
        } else {
          // For other content types, use toString or a specific extraction method
          resultText = firstContent.toString();
        }
      }

      return app.ChatMessage.tool(
        resultText,
        toolName: toolName,
        toolId: toolName,
      );
    } catch (e) {
      return app.ChatMessage.error('Tool execution error: $e');
    }
  }

  // Chat with LLM
  Future<app.ChatMessage> chat(String message, {bool enableTools = false}) async {
    if (_llmId == null) {
      return app.ChatMessage.error('No LLM configured');
    }

    try {
      final response = await _mcp.chat(
        _llmId!,
        message,
        enableTools: enableTools,
      );

      // Map tool calls if present
      List<app.ToolCall>? toolCalls;
      if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
        toolCalls = response.toolCalls!.map((tc) =>
            app.ToolCall(
              id: tc.id,
              name: tc.name,
              arguments: tc.arguments,
            )
        ).toList();
      }

      return app.ChatMessage.assistant(
        response.text,
        toolCalls: toolCalls,
        metadata: response.metadata,
      );
    } catch (e) {
      return app.ChatMessage.error('Chat error: $e');
    }
  }

  // Stream chat with LLM
  Stream<app.ChatMessage> streamChat(String message, {bool enableTools = false}) async* {
    if (_llmId == null) {
      yield app.ChatMessage.error('No LLM configured');
      return;
    }

    try {
      final streamResponse = _mcp.streamChat(
        _llmId!,
        message,
        enableTools: enableTools,
      );

      String accumulatedText = '';
      app.ChatMessage? resultMessage;

      await for (final chunk in streamResponse) {
        accumulatedText += chunk.textChunk;

        if (resultMessage == null) {
          // First chunk
          resultMessage = app.ChatMessage.assistant(
            accumulatedText,
            isStreaming: true,
          );
        } else {
          // Update message
          resultMessage = resultMessage.copyWith(
            content: accumulatedText,
          );
        }

        yield resultMessage;
      }

      // Final message with any tool calls
      if (resultMessage != null) {
        // Update streaming status on final message
        yield resultMessage.setStreamingState(false);
      }
    } catch (e) {
      yield app.ChatMessage.error('Stream chat error: $e');
    }
  }

  // Get system status
  Map<String, dynamic> getSystemStatus() {
    return _mcp.getSystemStatus();
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/settings_provider.dart';
import 'message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _enableTools = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connectionProvider.isConnected
                  ? Icons.cloud_done
                  : Icons.cloud_off,
              size: 20,
              color: connectionProvider.isConnected
                  ? Colors.green
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('MCP Chat'),
          ],
        ),
        actions: [
          if (!connectionProvider.isConnected)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => _connectToServer(context),
              tooltip: 'Connect',
            ),
          if (connectionProvider.isConnected)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () => _clearChat(context),
              tooltip: 'Clear Chat',
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          if (!connectionProvider.isConnected)
            _buildConnectionAlert(context),

          // Messages list
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildEmptyChat()
                : _buildMessagesList(),
          ),

          // Input area
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildConnectionAlert(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              connectionProvider.errorMessage ?? 'Not connected to MCP server',
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
          ElevatedButton(
            onPressed: () => _connectToServer(context),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final chatProvider = Provider.of<ChatProvider>(context);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.messages[index];
        return MessageBubble(
          message: message,
          onToolExecute: _executeToolCall,
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tools toggle
          IconButton(
            icon: Icon(
              _enableTools ? Icons.build : Icons.build_outlined,
              color: _enableTools
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: connectionProvider.isConnected
                ? () => setState(() => _enableTools = !_enableTools)
                : null,
            tooltip: 'Enable Tools',
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              minLines: 1,
              maxLines: 5,
              enabled: connectionProvider.isConnected,
              textInputAction: TextInputAction.send,
              onSubmitted: (text) => _sendMessage(context),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          chatProvider.isLoading
              ? Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : IconButton(
            icon: const Icon(Icons.send),
            onPressed: connectionProvider.isConnected
                ? () => _sendMessage(context)
                : null,
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) async {
    if (_messageController.text.trim().isEmpty) return;

    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    // Check connection
    if (!connectionProvider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to MCP server')),
      );
      return;
    }

    final userMessage = _messageController.text.trim();
    chatProvider.addUserMessage(userMessage);
    _messageController.clear();

    // Scroll to bottom
    _scrollToBottom();

    // Set loading state
    chatProvider.setLoading(true);

    try {
      final mcpService = connectionProvider.getMcpService();

      // Check if LLM is available, if not we'll use the MCP server directly
      if (mcpService.llmId != null) {
        // Get settings and use streaming if possible
        final useCache = settingsProvider.settings.useMessageCache;

        if (settingsProvider.settings.useMessageCache) {
          // Send message with streaming for a better UX
          chatProvider.addAssistantMessage('', isStreaming: true);

          final stream = mcpService.streamChat(
            userMessage,
            enableTools: _enableTools,
          );

          await for (final response in stream) {
            chatProvider.updateMessage(
              chatProvider.currentMessageId,
              response,
            );

            // Scroll to bottom with each update
            _scrollToBottom();
          }
        } else {
          // Send message without streaming
          final response = await mcpService.chat(
            userMessage,
            enableTools: _enableTools,
          );

          chatProvider.addMessage(response);

          // If tools are present in the response, execute them
          if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
            for (final toolCall in response.toolCalls!) {
              await _executeToolCall(toolCall);
            }
          }
        }
      } else {
        // No LLM available, try to use a tool instead
        chatProvider.addAssistantMessage(
          "I don't have an LLM configured, but I can try to execute a tool if you specify one.",
        );
      }
    } catch (e) {
      chatProvider.addErrorMessage('Error: $e');
    } finally {
      chatProvider.setLoading(false);
      _scrollToBottom();
    }
  }

  Future<void> _executeToolCall(ToolCall toolCall) async {
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      // Show loading state
      chatProvider.setLoading(true);

      // Execute the tool
      final mcpService = connectionProvider.getMcpService();
      final toolResponse = await mcpService.callTool(
        toolCall.name,
        toolCall.arguments,
      );

      // Add response to chat
      chatProvider.addMessage(toolResponse);

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      chatProvider.addErrorMessage('Tool execution error: $e');
    } finally {
      chatProvider.setLoading(false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _connectToServer(BuildContext context) async {
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    // Initialize MCP service with settings
    try {
      await connectionProvider.getMcpService().initialize(settingsProvider.settings);

      // Connect to server
      final success = await connectionProvider.connect();

      if (success) {
        // Show welcome message
        Provider.of<ChatProvider>(context, listen: false).addSystemMessage(
          'Connected to MCP server. Start chatting!',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  void _clearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false).clearMessages();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
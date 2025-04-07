import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentMessageId = '';

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentMessageId => _currentMessageId;

  // Add a new message
  void addMessage(ChatMessage message) {
    _messages.add(message);
    _currentMessageId = message.id;
    notifyListeners();
  }

  // Update a message by ID
  void updateMessage(String id, ChatMessage updatedMessage) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _messages[index] = updatedMessage;
      notifyListeners();
    }
  }

  // Append content to the current message (for streaming)
  void appendToCurrentMessage(String content) {
    final index = _messages.indexWhere((m) => m.id == _currentMessageId);
    if (index != -1) {
      _messages[index] = _messages[index].appendContent(content);
      notifyListeners();
    }
  }

  // Set streaming state for current message
  void setCurrentMessageStreaming(bool isStreaming) {
    final index = _messages.indexWhere((m) => m.id == _currentMessageId);
    if (index != -1) {
      _messages[index] = _messages[index].setStreamingState(isStreaming);
      notifyListeners();
    }
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void setErrorMessage(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Add a user message and set as current
  void addUserMessage(String content) {
    final message = ChatMessage.user(content);
    _messages.add(message);
    _currentMessageId = message.id;
    notifyListeners();
  }

  // Add an assistant message and set as current
  void addAssistantMessage(String content, {bool isStreaming = false, List<ToolCall>? toolCalls}) {
    final message = ChatMessage.assistant(
      content,
      isStreaming: isStreaming,
      toolCalls: toolCalls,
    );
    _messages.add(message);
    _currentMessageId = message.id;
    notifyListeners();
  }

  // Add a system message
  void addSystemMessage(String content) {
    final message = ChatMessage.system(content);
    _messages.add(message);
    notifyListeners();
  }

  // Add an error message
  void addErrorMessage(String content) {
    final message = ChatMessage.error(content);
    _messages.add(message);
    notifyListeners();
  }

  // Clear all messages
  void clearMessages() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  // Get the last assistant message
  ChatMessage? getLastAssistantMessage() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == MessageRole.assistant) {
        return _messages[i];
      }
    }
    return null;
  }

  // Get the last user message
  ChatMessage? getLastUserMessage() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == MessageRole.user) {
        return _messages[i];
      }
    }
    return null;
  }

  // Get all messages as context
  String getMessagesAsContext({int maxTokens = 4000}) {
    // This is a simple approximation, not exact token counting
    String context = '';

    for (final message in _messages) {
      final role = message.role.toString().split('.').last;
      final content = message.content;

      // Simple token estimation (4 chars ~= 1 token)
      final approxTokens = (context.length / 4).ceil();
      if (approxTokens >= maxTokens) break;

      context += '$role: $content\n\n';
    }

    return context;
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(ToolCall)? onToolExecute;

  const MessageBubble({
    super.key,
    required this.message,
    this.onToolExecute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: _isSentByUser()
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildSender(context),
          const SizedBox(height: 4),
          _buildContent(context),

          // Tool calls section
          if (message.toolCalls != null && message.toolCalls!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 8,
                left: _isSentByUser() ? 48 : 0,
                right: _isSentByUser() ? 0 : 48,
              ),
              child: _buildToolCalls(context),
            ),
        ],
      ),
    );
  }

  Widget _buildSender(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: _isSentByUser() ? 0 : 12,
        right: _isSentByUser() ? 12 : 0,
      ),
      child: Text(
        _getSenderText(),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      decoration: BoxDecoration(
        color: _getBubbleColor(context),
        borderRadius: _getBubbleRadius(),
      ),
      child: Stack(
        children: [
          // Message content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildMessageContent(context),
          ),

          // Loading indicator
          if (message.isStreaming)
            Positioned(
              right: 8,
              bottom: 8,
              child: SpinKitThreeBounce(
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.role) {
      case MessageRole.error:
        return Text(
          message.content,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
          ),
        );

      case MessageRole.system:
        return Text(
          message.content,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );

      default:
      // Render markdown for user, assistant, and tool messages
        return MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: _getTextColor(context),
            ),
            code: TextStyle(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
            codeblockDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
    }
  }

  Widget _buildToolCalls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: message.toolCalls!.map((toolCall) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tool header
                Row(
                  children: [
                    const Icon(Icons.build, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Tool: ${toolCall.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Tool arguments
                const Text(
                  'Arguments:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(toolCall.arguments.toString()),

                // Execute button
                if (onToolExecute != null && toolCall.result == null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Execute'),
                      onPressed: () => onToolExecute!(toolCall),
                    ),
                  ),

                // Tool result if available
                if (toolCall.result != null) ...[
                  const Divider(),
                  const Text(
                    'Result:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(toolCall.result!),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Helper methods
  bool _isSentByUser() {
    return message.role == MessageRole.user;
  }

  String _getSenderText() {
    switch (message.role) {
      case MessageRole.user:
        return 'You';
      case MessageRole.assistant:
        return 'Assistant';
      case MessageRole.system:
        return 'System';
      case MessageRole.tool:
        return message.metadata?['toolName'] ?? 'Tool';
      case MessageRole.error:
        return 'Error';
    }
  }

  Color _getBubbleColor(BuildContext context) {
    switch (message.role) {
      case MessageRole.user:
        return Theme.of(context).colorScheme.primaryContainer;
      case MessageRole.assistant:
        return Theme.of(context).colorScheme.secondaryContainer;
      case MessageRole.system:
        return Theme.of(context).colorScheme.surfaceVariant;
      case MessageRole.tool:
        return Theme.of(context).colorScheme.tertiaryContainer;
      case MessageRole.error:
        return Theme.of(context).colorScheme.errorContainer;
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (message.role) {
      case MessageRole.user:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case MessageRole.assistant:
        return Theme.of(context).colorScheme.onSecondaryContainer;
      case MessageRole.system:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case MessageRole.tool:
        return Theme.of(context).colorScheme.onTertiaryContainer;
      case MessageRole.error:
        return Theme.of(context).colorScheme.onErrorContainer;
    }
  }

  BorderRadius _getBubbleRadius() {
    const radius = Radius.circular(16);

    if (_isSentByUser()) {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: Radius.circular(4),
      );
    } else {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: Radius.circular(4),
        bottomRight: radius,
      );
    }
  }
}
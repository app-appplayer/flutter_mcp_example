import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';

class ApiKeyForm extends StatefulWidget {
  final String provider;
  final Function(String) onSave;
  final Function() onDelete;
  final bool isVisible;
  final Function() onToggleVisibility;

  const ApiKeyForm({
    Key? key,
    required this.provider,
    required this.onSave,
    required this.onDelete,
    required this.isVisible,
    required this.onToggleVisibility,
  }) : super(key: key);

  @override
  State<ApiKeyForm> createState() => _ApiKeyFormState();
}

class _ApiKeyFormState extends State<ApiKeyForm> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    setState(() => _isLoading = true);

    try {
      final apiKey = await SecureStorageService.getApiKey(widget.provider);

      setState(() {
        _hasKey = apiKey != null && apiKey.isNotEmpty;
        if (_hasKey && widget.isVisible) {
          _apiKeyController.text = apiKey!;
        } else if (_hasKey) {
          _apiKeyController.text = '••••••••••••••••••••••••••';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasKey = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider name
            Text(
              _getProviderDisplayName(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // API key input
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: _hasKey ? null : 'Enter your API key',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Visibility toggle
                    IconButton(
                      icon: Icon(
                        widget.isVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        widget.onToggleVisibility();

                        // If we're toggling off visibility and have a key
                        if (!widget.isVisible && _hasKey) {
                          _loadApiKey();
                        }
                      },
                      tooltip: widget.isVisible
                          ? 'Hide API Key'
                          : 'Show API Key',
                    ),

                    // Delete button (if we have a key)
                    if (_hasKey)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _showDeleteConfirmation,
                        tooltip: 'Delete API Key',
                      ),
                  ],
                ),
              ),
              obscureText: _hasKey && !widget.isVisible,
              enableSuggestions: false,
              autocorrect: false,
            ),
            const SizedBox(height: 16),

            // Save button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _loadApiKey(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveApiKey,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveApiKey() {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key cannot be empty')),
      );
      return;
    }

    print('Saving API key for provider: ${widget.provider}, key length: ${apiKey.length}');
    widget.onSave(apiKey);

    setState(() {
      _hasKey = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_getProviderDisplayName()} API Key saved')),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API Key'),
        content: Text(
          'Are you sure you want to delete the API key for ${_getProviderDisplayName()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete();
              setState(() {
                _hasKey = false;
                _apiKeyController.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_getProviderDisplayName()} API Key deleted'),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getProviderDisplayName() {
    switch (widget.provider.toLowerCase()) {
      case 'openai':
        return 'OpenAI';
      case 'claude':
        return 'Anthropic Claude';
      case 'together':
        return 'Together AI';
      default:
        return widget.provider;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_mcp/flutter_mcp.dart';
import 'package:provider/provider.dart';
import '../models/connection_config.dart';
import '../providers/settings_provider.dart';
import '../services/secure_storage_service.dart';

class ConnectionFormScreen extends StatefulWidget {
  final ConnectionConfig? initialConfig;

  const ConnectionFormScreen({Key? key, this.initialConfig}) : super(key: key);

  @override
  State<ConnectionFormScreen> createState() => _ConnectionFormScreenState();
}

class _ConnectionFormScreenState extends State<ConnectionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientVersionController = TextEditingController();
  final TextEditingController _transportCommandController = TextEditingController();
  final TextEditingController _transportArgsController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _authTokenController = TextEditingController(); // Added auth token controller

  // Form values
  bool _useSSE = true;
  String? _selectedLlmProvider;
  String? _selectedModelName;
  bool _rootsCapability = true;
  bool _rootsListChangedCapability = false;
  bool _samplingCapability = false;

  @override
  void initState() {
    super.initState();

    // Load initial values if editing an existing config
    if (widget.initialConfig != null) {
      _loadInitialValues();
    } else {
      // Default values for new connections
      _clientNameController.text = 'MCP Test Client';
      _clientVersionController.text = '1.0.0';
      _serverUrlController.text = 'http://localhost:8080/sse';
    }
  }

  void _loadInitialValues() {
    final config = widget.initialConfig!;

    _nameController.text = config.name;
    _clientNameController.text = config.clientName;
    _clientVersionController.text = config.clientVersion;
    _transportCommandController.text = config.transportCommand ?? '';
    _transportArgsController.text = config.transportArgs?.join(' ') ?? '';
    _serverUrlController.text = config.serverUrl ?? '';
    _authTokenController.text = config.authToken ?? ''; // Load auth token

    _useSSE = config.useSSE;
    _selectedLlmProvider = config.llmProvider;
    _selectedModelName = config.modelName;

    if (config.capabilities != null) {
      _rootsCapability = config.capabilities!.roots;
      _rootsListChangedCapability = config.capabilities!.rootsListChanged;
      _samplingCapability = config.capabilities!.sampling;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientNameController.dispose();
    _clientVersionController.dispose();
    _transportCommandController.dispose();
    _transportArgsController.dispose();
    _serverUrlController.dispose();
    _authTokenController.dispose(); // Dispose auth token controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialConfig != null ? 'Edit Connection' : 'New Connection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConnection,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic information
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Connection name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Connection Name',
                hintText: 'Enter a name for this connection',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Client information
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Client Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _clientVersionController,
                    decoration: const InputDecoration(
                      labelText: 'Version',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Connection type
            const Text(
              'Connection Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Transport type selection
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('SSE (Server-Sent Events)'),
                    value: true,
                    groupValue: _useSSE,
                    onChanged: (value) {
                      setState(() {
                        _useSSE = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Standard I/O'),
                    value: false,
                    groupValue: _useSSE,
                    onChanged: (value) {
                      setState(() {
                        _useSSE = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SSE connection fields
            if (_useSSE)
              Column(
                children: [
                  TextFormField(
                    controller: _serverUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://localhost:8080/sse',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_useSSE && (value == null || value.isEmpty)) {
                        return 'Please enter a server URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Add Auth Token field
                  TextFormField(
                    controller: _authTokenController,
                    decoration: const InputDecoration(
                      labelText: 'Authentication Token (optional)',
                      hintText: 'Enter auth token if required',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              )
            // Stdio connection fields
            else
              Column(
                children: [
                  TextFormField(
                    controller: _transportCommandController,
                    decoration: const InputDecoration(
                      labelText: 'Transport Command',
                      hintText: 'server',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_useSSE && (value == null || value.isEmpty)) {
                        return 'Please enter a command';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _transportArgsController,
                    decoration: const InputDecoration(
                      labelText: 'Command Arguments (space-separated)',
                      hintText: '--port 8080',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add Auth Token field
                  TextFormField(
                    controller: _authTokenController,
                    decoration: const InputDecoration(
                      labelText: 'Authentication Token (optional)',
                      hintText: 'Enter auth token if required',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // LLM integration
            const Text(
              'LLM Integration (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // LLM provider dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'LLM Provider',
                border: OutlineInputBorder(),
              ),
              value: _selectedLlmProvider,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ...settingsProvider.settings.providerList.map((provider) {
                  return DropdownMenuItem<String>(
                    value: provider,
                    child: Text(_getProviderDisplayName(provider)),
                  );
                }).toList(),
              ],
              onChanged: (value) async {
                setState(() {
                  _selectedLlmProvider = value;
                  _selectedModelName = null;
                });

                // Check if API key is set for this provider
                if (value != null) {
                  try {
                    final apiKey = await SecureStorageService.getApiKey(value);
                    final hasKey = apiKey != null && apiKey.isNotEmpty;
                    print('Checking API key for $value: ${hasKey ? "found" : "not found"}');

                    if (!hasKey) {
                      if (!mounted) return;
                      _showApiKeyWarning(context, value);
                    }
                  } catch (e) {
                    print('Error checking API key: $e');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error checking API key: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // Model dropdown (only if provider is selected)
            if (_selectedLlmProvider != null)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
                value: _selectedModelName,
                items: settingsProvider.settings.modelsByProvider[_selectedLlmProvider]
                    ?.entries
                    .map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList() ?? [],
                onChanged: (value) {
                  setState(() {
                    _selectedModelName = value;
                  });
                },
              ),
            const SizedBox(height: 24),

            // Client capabilities
            const Text(
              'Client Capabilities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Capability checkboxes
            CheckboxListTile(
              title: const Text('Roots'),
              subtitle: const Text('Client can access resources from roots'),
              value: _rootsCapability,
              onChanged: (value) {
                setState(() {
                  _rootsCapability = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Roots list changed'),
              subtitle: const Text('Client receives notifications when roots list changes'),
              value: _rootsListChangedCapability,
              onChanged: (value) {
                setState(() {
                  _rootsListChangedCapability = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Sampling'),
              subtitle: const Text('Client can sample from the model'),
              value: _samplingCapability,
              onChanged: (value) {
                setState(() {
                  _samplingCapability = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveConnection() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Parse command arguments
    List<String>? transportArgs;
    if (!_useSSE && _transportArgsController.text.isNotEmpty) {
      transportArgs = _transportArgsController.text.split(' ');
    }

    // Get auth token (if provided)
    String? authToken;
    if (_authTokenController.text.isNotEmpty) {
      authToken = _authTokenController.text.trim();
    }

    // Create connection configuration
    final config = ConnectionConfig(
      name: _nameController.text,
      clientName: _clientNameController.text,
      clientVersion: _clientVersionController.text,
      transportCommand: _useSSE ? null : _transportCommandController.text,
      transportArgs: transportArgs,
      serverUrl: _useSSE ? _serverUrlController.text : null,
      useSSE: _useSSE,
      capabilities: ClientCapabilities(
        roots: _rootsCapability,
        rootsListChanged: _rootsListChangedCapability,
        sampling: _samplingCapability,
      ),
      llmProvider: _selectedLlmProvider,
      modelName: _selectedModelName,
      authToken: authToken, // Include auth token in config
    );

    // Validate the configuration
    final validationError = config.validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    // Return the configuration
    Navigator.pop(context, config);
  }

  void _showApiKeyWarning(BuildContext context, String provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Not Found'),
        content: Text(
          'No API key is set for ${_getProviderDisplayName(provider)}. '
              'Please add an API key in Settings before using this LLM provider.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getProviderDisplayName(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return 'OpenAI';
      case 'claude':
        return 'Anthropic Claude';
      case 'together':
        return 'Together AI';
      default:
        return provider;
    }
  }
}
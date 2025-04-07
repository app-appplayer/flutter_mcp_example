import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/connection_config.dart';
import '../providers/connection_provider.dart';
import '../providers/settings_provider.dart';
import '../services/mcp_client_service.dart';
import 'connection_form_screen.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createNewConnection(context),
            tooltip: 'New Connection',
          ),
        ],
      ),
      body: connectionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);

    return Column(
      children: [
        // Connection status
        _buildConnectionStatus(context),

        // Saved connections
        Expanded(
          child: connectionProvider.savedConnections.isEmpty
              ? _buildEmptyConnections(context)
              : _buildConnectionsList(context),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);
    final currentConfig = connectionProvider.currentConfig;

    if (currentConfig == null) {
      return const SizedBox.shrink();
    }

    final Color statusColor = connectionProvider.isConnected
        ? Colors.green
        : connectionProvider.connectionStatus == ConnectionStatus.connecting
        ? Colors.orange
        : Colors.red;

    final String statusText = connectionProvider.isConnected
        ? 'Connected'
        : connectionProvider.connectionStatus == ConnectionStatus.connecting
        ? 'Connecting...'
        : 'Disconnected';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Connection',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Connection details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection name
                  Text(
                    currentConfig.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),

                  // Client details
                  Text('Client: ${currentConfig.clientName} v${currentConfig.clientVersion}'),

                  // Transport type
                  Text(
                    'Transport: ${currentConfig.useSSE ? 'Server-Sent Events' : 'Standard I/O'}',
                  ),

                  // Transport details
                  if (currentConfig.useSSE && currentConfig.serverUrl != null)
                    Text('Server URL: ${currentConfig.serverUrl}')
                  else if (!currentConfig.useSSE && currentConfig.transportCommand != null)
                    Text('Command: ${currentConfig.transportCommand}'),

                  // LLM details
                  if (currentConfig.llmProvider != null && currentConfig.modelName != null)
                    Text(
                      'LLM: ${currentConfig.llmProvider} (${currentConfig.modelName})',
                    ),

                  // Status indicator
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (connectionProvider.errorMessage != null)
                        Expanded(
                          child: Text(
                            connectionProvider.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const Spacer(),

                      // Connect/disconnect button
                      connectionProvider.isConnected
                          ? OutlinedButton.icon(
                        icon: const Icon(Icons.link_off),
                        label: const Text('Disconnect'),
                        onPressed: () => _disconnectFromServer(context),
                      )
                          : ElevatedButton.icon(
                        icon: const Icon(Icons.link),
                        label: const Text('Connect'),
                        onPressed: connectionProvider.connectionStatus == ConnectionStatus.connecting
                            ? null
                            : () => _connectToServer(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyConnections(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No saved connections',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new connection to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Connection'),
            onPressed: () => _createNewConnection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsList(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: connectionProvider.savedConnections.length,
      itemBuilder: (context, index) {
        final connectionName = connectionProvider.savedConnections[index];
        final isSelected = connectionProvider.currentConfig?.name == connectionName;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            title: Text(connectionName),
            subtitle: isSelected
                ? const Text('Current connection')
                : null,
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editConnection(context, connectionName),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteConnection(context, connectionName),
                  tooltip: 'Delete',
                ),
              ],
            ),
            onTap: isSelected
                ? null
                : () => _selectConnection(context, connectionName),
          ),
        );
      },
    );
  }

  void _connectToServer(BuildContext context) async {
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    // Initialize MCP service with settings first
    await connectionProvider.getMcpService().initialize(settingsProvider.settings);

    // Connect using current configuration
    final success = await connectionProvider.connect();

    if (!success) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connectionProvider.errorMessage ?? 'Failed to connect',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connected successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _disconnectFromServer(BuildContext context) async {
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);

    try {
      await connectionProvider.disconnect();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disconnected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _selectConnection(BuildContext context, String connectionName) async {
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);

    // If already connected, ask to disconnect first
    if (connectionProvider.isConnected) {
      final shouldDisconnect = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disconnect?'),
          content: const Text(
            'You are currently connected. Switching connections will disconnect you from the current server.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Disconnect and Switch'),
            ),
          ],
        ),
      );

      if (shouldDisconnect != true) return;

      await connectionProvider.disconnect();
    }

    await connectionProvider.loadConnection(connectionName);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to $connectionName'),
        action: SnackBarAction(
          label: 'Connect',
          onPressed: () => _connectToServer(context),
        ),
      ),
    );
  }

  void _createNewConnection(BuildContext context) async {
    final result = await Navigator.push<ConnectionConfig>(
      context,
      MaterialPageRoute(
        builder: (context) => const ConnectionFormScreen(),
      ),
    );

    if (result != null) {
      if (!context.mounted) return;

      final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
      await connectionProvider.saveConnection(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created "${result.name}"'),
          action: SnackBarAction(
            label: 'Connect',
            onPressed: () => _connectToServer(context),
          ),
        ),
      );
    }
  }

  void _editConnection(BuildContext context, String connectionName) async {
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);

    // If editing current connection and connected, ask to disconnect first
    if (connectionProvider.currentConfig?.name == connectionName &&
        connectionProvider.isConnected) {
      final shouldDisconnect = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disconnect?'),
          content: const Text(
            'You are currently connected with this configuration. '
                'Editing will disconnect you from the current server.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Disconnect and Edit'),
            ),
          ],
        ),
      );

      if (shouldDisconnect != true) return;

      await connectionProvider.disconnect();
    }

    // Load the connection
    await connectionProvider.loadConnection(connectionName);

    if (!context.mounted) return;

    // Open the form with the current configuration
    final result = await Navigator.push<ConnectionConfig>(
      context,
      MaterialPageRoute(
        builder: (context) => ConnectionFormScreen(
          initialConfig: connectionProvider.currentConfig,
        ),
      ),
    );

    if (result != null) {
      if (!context.mounted) return;

      // Save the edited connection
      await connectionProvider.saveConnection(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "${result.name}"'),
          action: SnackBarAction(
            label: 'Connect',
            onPressed: () => _connectToServer(context),
          ),
        ),
      );
    }
  }

  void _deleteConnection(BuildContext context, String connectionName) async {
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);

    // If deleting current connection and connected, ask to disconnect first
    if (connectionProvider.currentConfig?.name == connectionName &&
        connectionProvider.isConnected) {
      final shouldDisconnect = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disconnect?'),
          content: const Text(
            'You are currently connected with this configuration. '
                'Deleting will disconnect you from the current server.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Disconnect and Delete'),
            ),
          ],
        ),
      );

      if (shouldDisconnect != true) return;

      await connectionProvider.disconnect();
    }

    // Confirm deletion
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text(
          'Are you sure you want to delete the connection "$connectionName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Delete the connection
    await connectionProvider.deleteConnection(connectionName);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "$connectionName"'),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/api_key_form.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetSettings(context),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: settingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAppearanceSection(context),
          const SizedBox(height: 24),
          _buildPerformanceSection(context),
          const SizedBox(height: 24),
          _buildBehaviorSection(context),
          const SizedBox(height: 24),
          _buildApiKeysSection(context),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Appearance'),
        _buildSettingItem(
          context: context,
          icon: Icons.brightness_6,
          title: 'Theme Mode',
          trailing: DropdownButton<ThemeMode>(
            value: settingsProvider.settings.themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                settingsProvider.setThemeMode(value);
              }
            },
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Performance'),
        _buildSettingItem(
          context: context,
          icon: Icons.speed,
          title: 'Enable Performance Monitoring',
          subtitle: 'Track resources and operation metrics',
          trailing: Switch(
            value: settingsProvider.settings.enablePerformanceMonitoring,
            onChanged: (value) {
              settingsProvider.togglePerformanceMonitoring(value);
            },
          ),
        ),
        _buildSettingItem(
          context: context,
          icon: Icons.memory,
          title: 'Memory Threshold',
          subtitle: 'High memory usage threshold in MB',
          trailing: DropdownButton<int>(
            value: settingsProvider.settings.highMemoryThresholdMB,
            onChanged: (int? value) {
              if (value != null) {
                settingsProvider.setMemoryThreshold(value);
              }
            },
            items: const [
              DropdownMenuItem(value: 256, child: Text('256 MB')),
              DropdownMenuItem(value: 512, child: Text('512 MB')),
              DropdownMenuItem(value: 1024, child: Text('1 GB')),
              DropdownMenuItem(value: 2048, child: Text('2 GB')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBehaviorSection(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Behavior'),
        _buildSettingItem(
          context: context,
          icon: Icons.storage,
          title: 'Use Message Cache',
          subtitle: 'Cache responses for better performance',
          trailing: Switch(
            value: settingsProvider.settings.useMessageCache,
            onChanged: (value) {
              settingsProvider.toggleMessageCache(value);
            },
          ),
        ),
        _buildSettingItem(
          context: context,
          icon: Icons.notifications,
          title: 'Background Service',
          subtitle: 'Keep service running in background',
          trailing: Switch(
            value: settingsProvider.settings.useBackgroundService,
            onChanged: (value) {
              settingsProvider.toggleBackgroundService(value);
            },
          ),
        ),
        _buildSettingItem(
          context: context,
          icon: Icons.system_update_alt,
          title: 'System Tray',
          subtitle: 'Show in system tray (desktop only)',
          trailing: Switch(
            value: settingsProvider.settings.showSystemTray,
            onChanged: (value) {
              settingsProvider.toggleSystemTray(value);
            },
          ),
        ),
        _buildSettingItem(
          context: context,
          icon: Icons.bug_report,
          title: 'Debug Logging',
          subtitle: 'Enable detailed logging',
          trailing: Switch(
            value: settingsProvider.settings.enableLogging,
            onChanged: (value) {
              settingsProvider.toggleLogging(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeysSection(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'API Keys'),

        // Show API key forms for each provider
        ...settingsProvider.settings.providerList.map((provider) {
          return ApiKeyForm(
            provider: provider,
            onSave: (apiKey) => settingsProvider.saveApiKey(provider, apiKey),
            onDelete: () => settingsProvider.deleteApiKey(provider),
            isVisible: settingsProvider.isApiKeyVisible(provider),
            onToggleVisibility: () => settingsProvider.toggleApiKeyVisibility(provider),
          );
        }).toList(),
      ],
    );
  }

  // Reusable widgets
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
    );
  }

  void _resetSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SettingsProvider>(context, listen: false).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
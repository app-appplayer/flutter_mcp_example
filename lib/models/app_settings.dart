import 'package:flutter/material.dart';
import 'package:flutter_mcp/flutter_mcp.dart';

class AppSettings {
  final ThemeMode themeMode;
  final bool enablePerformanceMonitoring;
  final int highMemoryThresholdMB;
  final bool useBackgroundService;
  final bool showSystemTray;
  final bool enableLogging;
  final bool useMessageCache;
  final List<String> providerList;
  final Map<String, Map<String, String>> modelsByProvider;

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.enablePerformanceMonitoring = false,
    this.highMemoryThresholdMB = 512,
    this.useBackgroundService = false,
    this.showSystemTray = true,
    this.enableLogging = true,
    this.useMessageCache = true,
    this.providerList = const ['openai', 'claude', 'together'],
    this.modelsByProvider = const {
      'openai': {
        'gpt-4': 'GPT-4',
        'gpt-4o': 'GPT-4o',
        'gpt-3.5-turbo': 'GPT-3.5 Turbo',
      },
      'claude': {
        'claude-3-opus-20240229': 'Claude 3 Opus',
        'claude-3-sonnet-20240229': 'Claude 3 Sonnet',
        'claude-3-haiku-20240307': 'Claude 3 Haiku',
      },
      'together': {
        'mistralai/Mistral-7B-Instruct-v0.2': 'Mistral 7B',
        'meta-llama/Llama-2-70b-chat-hf': 'Llama 2 70B',
      },
    },
  });

  // Copy with method
  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? enablePerformanceMonitoring,
    int? highMemoryThresholdMB,
    bool? useBackgroundService,
    bool? showSystemTray,
    bool? enableLogging,
    bool? useMessageCache,
    List<String>? providerList,
    Map<String, Map<String, String>>? modelsByProvider,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      enablePerformanceMonitoring: enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
      highMemoryThresholdMB: highMemoryThresholdMB ?? this.highMemoryThresholdMB,
      useBackgroundService: useBackgroundService ?? this.useBackgroundService,
      showSystemTray: showSystemTray ?? this.showSystemTray,
      enableLogging: enableLogging ?? this.enableLogging,
      useMessageCache: useMessageCache ?? this.useMessageCache,
      providerList: providerList ?? this.providerList,
      modelsByProvider: modelsByProvider ?? this.modelsByProvider,
    );
  }

  // To JSON method
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'highMemoryThresholdMB': highMemoryThresholdMB,
      'useBackgroundService': useBackgroundService,
      'showSystemTray': showSystemTray,
      'enableLogging': enableLogging,
      'useMessageCache': useMessageCache,
      'providerList': providerList,
      'modelsByProvider': modelsByProvider,
    };
  }

  // From JSON factory
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
      enablePerformanceMonitoring: json['enablePerformanceMonitoring'] as bool? ?? false,
      highMemoryThresholdMB: json['highMemoryThresholdMB'] as int? ?? 512,
      useBackgroundService: json['useBackgroundService'] as bool? ?? false,
      showSystemTray: json['showSystemTray'] as bool? ?? true,
      enableLogging: json['enableLogging'] as bool? ?? true,
      useMessageCache: json['useMessageCache'] as bool? ?? true,
      providerList: json['providerList'] != null
          ? List<String>.from(json['providerList'])
          : ['openai', 'claude', 'together'],
      modelsByProvider: json['modelsByProvider'] != null
          ? Map<String, Map<String, String>>.from(
        (json['modelsByProvider'] as Map).map(
              (key, value) => MapEntry(
            key as String,
            Map<String, String>.from(value as Map),
          ),
        ),
      )
          : const {
        'openai': {
          'gpt-4': 'GPT-4',
          'gpt-4o': 'GPT-4o',
          'gpt-3.5-turbo': 'GPT-3.5 Turbo',
        },
        'claude': {
          'claude-3-opus-20240229': 'Claude 3 Opus',
          'claude-3-sonnet-20240229': 'Claude 3 Sonnet',
          'claude-3-haiku-20240307': 'Claude 3 Haiku',
        },
        'together': {
          'mistralai/Mistral-7B-Instruct-v0.2': 'Mistral 7B',
          'meta-llama/Llama-2-70b-chat-hf': 'Llama 2 70B',
        },
      },
    );
  }

  // Get LLM configuration for a provider and model
  LlmConfiguration? getLlmConfiguration(String provider, String model, String apiKey) {
    if (!providerList.contains(provider)) {
      return null;
    }

    // Check if model exists for provider
    final models = modelsByProvider[provider];
    if (models == null || !models.containsKey(model)) {
      return null;
    }

    switch (provider.toLowerCase()) {
      case 'openai':
        return LlmConfiguration(
          apiKey: apiKey,
          model: model,
          retryOnFailure: true,
          maxRetries: 3,
          timeout: const Duration(seconds: 60),
        );
      case 'claude':
        return LlmConfiguration(
          apiKey: apiKey,
          model: model,
          retryOnFailure: true,
          maxRetries: 2,
          timeout: const Duration(seconds: 120),
        );
      case 'together':
        return LlmConfiguration(
          apiKey: apiKey,
          model: model,
          baseUrl: 'https://api.together.xyz',
          retryOnFailure: true,
          maxRetries: 2,
          timeout: const Duration(seconds: 90),
        );
      default:
        return LlmConfiguration(
          apiKey: apiKey,
          model: model,
          retryOnFailure: true,
          maxRetries: 2,
        );
    }
  }
}
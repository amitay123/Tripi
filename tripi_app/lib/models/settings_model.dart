import 'package:flutter/material.dart';

/// Immutable settings snapshot consumed by the AI engine.
/// Locked at generation-start to prevent mid-generation drift.
class SettingsSnapshot {
  final String intensityLevel; // 'relaxed' | 'balanced' | 'intensive'
  final int defaultAdults;
  final int defaultChildren;
  final List<String> tripStyles;
  final String language; // 'en' | 'he'

  const SettingsSnapshot({
    required this.intensityLevel,
    required this.defaultAdults,
    required this.defaultChildren,
    required this.tripStyles,
    required this.language,
  });

  /// Maps intensity level string → 0.0–1.0 value for UserPreferenceService.
  double get intensityFloat {
    switch (intensityLevel) {
      case 'relaxed':
        return 0.2;
      case 'intensive':
        return 0.85;
      default:
        return 0.5; // balanced
    }
  }
}

/// Full, mutable settings state stored in SettingsProvider.
class SettingsModel {
  final String intensityLevel;
  final int defaultAdults;
  final int defaultChildren;
  final List<String> tripStyles;

  // Notifications — granular
  final bool securityAlerts;
  final bool pushItineraryReminders;
  final bool pushAiSuggestions;
  final bool pushTravelAlerts;
  final bool pushPromotions;
  final bool emailNewsletters;
  final bool emailProductUpdates;
  final bool emailRecommendations;

  // App
  final String darkMode; // 'system' | 'light' | 'dark'
  final String language;

  // Subscription (future-ready)
  final String subscriptionTier;
  final int aiGenerationLimit;
  final bool premiumFeaturesEnabled;

  final DateTime updatedAt;

  const SettingsModel({
    this.intensityLevel = 'balanced',
    this.defaultAdults = 2,
    this.defaultChildren = 0,
    this.tripStyles = const [],
    this.securityAlerts = true,
    this.pushItineraryReminders = true,
    this.pushAiSuggestions = true,
    this.pushTravelAlerts = true,
    this.pushPromotions = false,
    this.emailNewsletters = false,
    this.emailProductUpdates = true,
    this.emailRecommendations = true,
    this.darkMode = 'system',
    this.language = 'en',
    this.subscriptionTier = 'free',
    this.aiGenerationLimit = 10,
    this.premiumFeaturesEnabled = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? const _EpochDateTime();

  ThemeMode get themeMode {
    switch (darkMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Locale get locale => Locale(language);

  SettingsSnapshot toSnapshot() => SettingsSnapshot(
        intensityLevel: intensityLevel,
        defaultAdults: defaultAdults,
        defaultChildren: defaultChildren,
        tripStyles: List.unmodifiable(tripStyles),
        language: language,
      );

  SettingsModel copyWith({
    String? intensityLevel,
    int? defaultAdults,
    int? defaultChildren,
    List<String>? tripStyles,
    bool? securityAlerts,
    bool? pushItineraryReminders,
    bool? pushAiSuggestions,
    bool? pushTravelAlerts,
    bool? pushPromotions,
    bool? emailNewsletters,
    bool? emailProductUpdates,
    bool? emailRecommendations,
    String? darkMode,
    String? language,
    String? subscriptionTier,
    int? aiGenerationLimit,
    bool? premiumFeaturesEnabled,
    DateTime? updatedAt,
  }) {
    return SettingsModel(
      intensityLevel: intensityLevel ?? this.intensityLevel,
      defaultAdults: defaultAdults ?? this.defaultAdults,
      defaultChildren: defaultChildren ?? this.defaultChildren,
      tripStyles: tripStyles ?? this.tripStyles,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      pushItineraryReminders:
          pushItineraryReminders ?? this.pushItineraryReminders,
      pushAiSuggestions: pushAiSuggestions ?? this.pushAiSuggestions,
      pushTravelAlerts: pushTravelAlerts ?? this.pushTravelAlerts,
      pushPromotions: pushPromotions ?? this.pushPromotions,
      emailNewsletters: emailNewsletters ?? this.emailNewsletters,
      emailProductUpdates: emailProductUpdates ?? this.emailProductUpdates,
      emailRecommendations: emailRecommendations ?? this.emailRecommendations,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      aiGenerationLimit: aiGenerationLimit ?? this.aiGenerationLimit,
      premiumFeaturesEnabled:
          premiumFeaturesEnabled ?? this.premiumFeaturesEnabled,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      intensityLevel: json['intensity_level'] as String? ?? 'balanced',
      defaultAdults: (json['default_adults'] as num?)?.toInt() ?? 2,
      defaultChildren: (json['default_children'] as num?)?.toInt() ?? 0,
      tripStyles: _parseStringList(json['trip_styles']),
      securityAlerts: json['security_alerts'] as bool? ?? true,
      pushItineraryReminders:
          json['push_itinerary_reminders'] as bool? ?? true,
      pushAiSuggestions: json['push_ai_suggestions'] as bool? ?? true,
      pushTravelAlerts: json['push_travel_alerts'] as bool? ?? true,
      pushPromotions: json['push_promotions'] as bool? ?? false,
      emailNewsletters: json['email_newsletters'] as bool? ?? false,
      emailProductUpdates: json['email_product_updates'] as bool? ?? true,
      emailRecommendations: json['email_recommendations'] as bool? ?? true,
      darkMode: json['dark_mode'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      aiGenerationLimit:
          (json['ai_generation_limit'] as num?)?.toInt() ?? 10,
      premiumFeaturesEnabled:
          json['premium_features_enabled'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'intensity_level': intensityLevel,
        'default_adults': defaultAdults,
        'default_children': defaultChildren,
        'trip_styles': tripStyles,
        'security_alerts': securityAlerts,
        'push_itinerary_reminders': pushItineraryReminders,
        'push_ai_suggestions': pushAiSuggestions,
        'push_travel_alerts': pushTravelAlerts,
        'push_promotions': pushPromotions,
        'email_newsletters': emailNewsletters,
        'email_product_updates': emailProductUpdates,
        'email_recommendations': emailRecommendations,
        'dark_mode': darkMode,
        'language': language,
        'subscription_tier': subscriptionTier,
        'ai_generation_limit': aiGenerationLimit,
        'premium_features_enabled': premiumFeaturesEnabled,
        'updated_at': updatedAt.toIso8601String(),
      };

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.cast<String>();
    return [];
  }
}

/// Used as a compile-time const default for updatedAt.
class _EpochDateTime implements DateTime {
  const _EpochDateTime();

  @override
  DateTime toLocal() => DateTime.fromMillisecondsSinceEpoch(0);

  @override
  String toIso8601String() => '1970-01-01T00:00:00.000Z';

  // Forward all remaining DateTime members to a real instance.
  DateTime get _d => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  @override
  bool operator ==(Object other) => _d == other;
  @override
  int get hashCode => _d.hashCode;
  @override
  String toString() => _d.toString();
  @override
  DateTime add(Duration duration) => _d.add(duration);
  @override
  DateTime subtract(Duration duration) => _d.subtract(duration);
  @override
  Duration difference(DateTime other) => _d.difference(other);
  @override
  bool isBefore(DateTime other) => _d.isBefore(other);
  @override
  bool isAfter(DateTime other) => _d.isAfter(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _d.isAtSameMomentAs(other);
  @override
  int compareTo(DateTime other) => _d.compareTo(other);
  @override
  DateTime toUtc() => _d.toUtc();
  @override
  int get year => 1970;
  @override
  int get month => 1;
  @override
  int get day => 1;
  @override
  int get hour => 0;
  @override
  int get minute => 0;
  @override
  int get second => 0;
  @override
  int get millisecond => 0;
  @override
  int get microsecond => 0;
  @override
  int get weekday => 4;
  @override
  int get millisecondsSinceEpoch => 0;
  @override
  int get microsecondsSinceEpoch => 0;
  @override
  bool get isUtc => true;
  @override
  String get timeZoneName => 'UTC';
  @override
  Duration get timeZoneOffset => Duration.zero;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Define feature flags
class FeatureFlags {
  static const String festivalMode = 'festival_mode';
  static const String specialOffers = 'special_offers';
  static const String enhancedAnimations = 'enhanced_animations';
  static const String seasonalThemes = 'seasonal_themes';
  static const String promotionalBanners = 'promotional_banners';
}

// Feature flag data model
class FeatureFlag {
  final String key;
  final bool enabled;
  final String? title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? metadata;

  FeatureFlag({
    required this.key,
    required this.enabled,
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.metadata,
  });

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      key: json['key'] ?? '',
      enabled: json['enabled'] ?? false,
      title: json['title'],
      description: json['description'],
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'enabled': enabled,
      'title': title,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

// Feature Flags Service to manage feature flags
class FeatureFlagsService {
  static const String _featureFlagsKey = 'feature_flags';

  Future<Map<String, FeatureFlag>> loadFeatureFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_featureFlagsKey) ?? '{}';
    final Map<String, dynamic> json = jsonDecode(jsonString);

    final flags = <String, FeatureFlag>{};
    json.forEach((key, value) {
      flags[key] = FeatureFlag.fromJson(value);
    });

    return flags;
  }

  Future<void> saveFeatureFlags(Map<String, FeatureFlag> flags) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> json = {};
    flags.forEach((key, flag) {
      json[key] = flag.toJson();
    });
    await prefs.setString(_featureFlagsKey, jsonEncode(json));
  }

  Future<void> updateFeatureFlag(String key, bool enabled) async {
    final flags = await loadFeatureFlags();
    flags[key] = FeatureFlag(
      key: key,
      enabled: enabled,
      title: flags[key]?.title,
      description: flags[key]?.description,
      startDate: flags[key]?.startDate,
      endDate: flags[key]?.endDate,
      metadata: flags[key]?.metadata,
    );
    await saveFeatureFlags(flags);
  }

  Future<bool> isFeatureEnabled(String key) async {
    final flags = await loadFeatureFlags();
    final flag = flags[key];
    
    // Check if the flag exists and is enabled
    if (flag != null) {
      // Check date range if specified
      if (flag.startDate != null && DateTime.now().isBefore(flag.startDate!)) {
        return false;
      }
      if (flag.endDate != null && DateTime.now().isAfter(flag.endDate!)) {
        return false;
      }
      return flag.enabled;
    }
    
    // Default to false if flag doesn't exist
    return false;
  }

  // Method to set up default feature flags
  Future<void> initializeDefaultFlags() async {
    final flags = await loadFeatureFlags();
    
    // Only add defaults if no flags exist yet
    if (flags.isEmpty) {
      final defaultFlags = {
        FeatureFlags.festivalMode: FeatureFlag(
          key: FeatureFlags.festivalMode,
          enabled: false,
          title: 'Festival Mode',
          description: 'Enable festival-themed UI elements',
          metadata: {
            'theme_color': '#FF6B35',
            'icon_pack': 'festival_icons',
          },
        ),
        FeatureFlags.specialOffers: FeatureFlag(
          key: FeatureFlags.specialOffers,
          enabled: false,
          title: 'Special Offers',
          description: 'Display special offers and discounts',
        ),
        FeatureFlags.enhancedAnimations: FeatureFlag(
          key: FeatureFlags.enhancedAnimations,
          enabled: true,
          title: 'Enhanced Animations',
          description: 'Enable enhanced UI animations',
        ),
        FeatureFlags.seasonalThemes: FeatureFlag(
          key: FeatureFlags.seasonalThemes,
          enabled: false,
          title: 'Seasonal Themes',
          description: 'Apply seasonal themes to UI',
        ),
        FeatureFlags.promotionalBanners: FeatureFlag(
          key: FeatureFlags.promotionalBanners,
          enabled: false,
          title: 'Promotional Banners',
          description: 'Show promotional banners',
        ),
      };
      
      await saveFeatureFlags(defaultFlags);
    }
  }
}

// Feature Flags Provider using AsyncNotifier pattern like other providers
final featureFlagsProvider = AsyncNotifierProvider<FeatureFlagsNotifier, Map<String, FeatureFlag>>(() => FeatureFlagsNotifier());

class FeatureFlagsNotifier extends AsyncNotifier<Map<String, FeatureFlag>> {
  final FeatureFlagsService _service = FeatureFlagsService();
  
  @override
  Future<Map<String, FeatureFlag>> build() async {
    await _service.initializeDefaultFlags(); // Initialize defaults on first load
    return await _service.loadFeatureFlags();
  }

  Future<void> updateFlag(String key, bool enabled) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateFeatureFlag(key, enabled);
      final flags = await _service.loadFeatureFlags();
      state = AsyncValue.data(flags);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.empty);
    }
  }

  Future<bool> isFeatureEnabled(String key) async {
    return await _service.isFeatureEnabled(key);
  }

  Future<void> refreshFlags() async {
    state = const AsyncValue.loading();
    try {
      final flags = await _service.loadFeatureFlags();
      state = AsyncValue.data(flags);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.empty);
    }
  }

  // Check if a specific feature flag is enabled
  bool get isFestivalModeEnabled {
    final flags = state.value ?? {};
    return flags[FeatureFlags.festivalMode]?.enabled ?? false;
  }
  
  bool get isSpecialOffersEnabled {
    final flags = state.value ?? {};
    return flags[FeatureFlags.specialOffers]?.enabled ?? false;
  }
  
  bool get isEnhancedAnimationsEnabled {
    final flags = state.value ?? {};
    return flags[FeatureFlags.enhancedAnimations]?.enabled ?? true;
  }
  
  bool get isSeasonalThemesEnabled {
    final flags = state.value ?? {};
    return flags[FeatureFlags.seasonalThemes]?.enabled ?? false;
  }
  
  bool get isPromotionalBannersEnabled {
    final flags = state.value ?? {};
    return flags[FeatureFlags.promotionalBanners]?.enabled ?? false;
  }
}
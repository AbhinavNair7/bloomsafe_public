import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/guide_item.dart';

/// Repository for accessing guide data
class GuideRepository {

  /// Factory constructor
  factory GuideRepository() => _instance;

  /// Private constructor
  GuideRepository._internal();
  /// Cache for guide items
  final Map<String, List<dynamic>> _cache = {};

  /// Singleton instance
  static final GuideRepository _instance = GuideRepository._internal();

  /// Fetches all pregnancy guide items
  Future<List<PregnancyGuideItem>> getPregnancyGuideItems() async {
    if (_cache.containsKey('pregnancy')) {
      return _cache['pregnancy']!.cast<PregnancyGuideItem>();
    }

    // Load from assets
    final jsonString = await rootBundle.loadString(
      'assets/data/pregnancy_guides.json',
    );
    final jsonData = json.decode(jsonString) as List;

    final items =
        jsonData.map((item) => PregnancyGuideItem.fromJson(item)).toList();

    _cache['pregnancy'] = items;
    return items;
  }

  /// Fetches all air quality guide items
  Future<List<AirQualityGuideItem>> getAirQualityGuideItems() async {
    if (_cache.containsKey('airQuality')) {
      return _cache['airQuality']!.cast<AirQualityGuideItem>();
    }

    // Load from assets
    final jsonString = await rootBundle.loadString(
      'assets/data/air_quality_guides.json',
    );
    final jsonData = json.decode(jsonString) as List;

    final items =
        jsonData.map((item) => AirQualityGuideItem.fromJson(item)).toList();

    _cache['airQuality'] = items;
    return items;
  }

  /// Filters pregnancy guide items by trimester
  Future<List<PregnancyGuideItem>> getPregnancyGuideItemsByTrimester(
    String trimester,
  ) async {
    final items = await getPregnancyGuideItems();
    return items.where((item) => item.trimester == trimester).toList();
  }

  /// Filters guide items by tag
  Future<List<T>> getGuideItemsByTag<T extends GuideItem>(
    List<T> items,
    String tag,
  ) async {
    return items.where((item) => item.tags.contains(tag)).toList();
  }
}

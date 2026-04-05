import 'package:flutter/foundation.dart';

/// Utility class for sanitizing PII (Personally Identifiable Information)
/// 
/// This implementation focuses specifically on sanitizing zipcodes to protect user privacy
/// while allowing other voluntarily provided information to pass through.
@immutable
class PiiSanitizer {
  /// Marker to indicate data has already been sanitized
  static const String sanitizedMarker = '__ALREADY_SANITIZED__';
  
  /// Checks if the given data has already been sanitized
  static bool isAlreadySanitized(Map<String, dynamic> data) {
    return data.containsKey(sanitizedMarker) && data[sanitizedMarker] == true;
  }
  
  /// Marks data as sanitized to prevent double-processing
  static Map<String, dynamic> markAsSanitized(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    result[sanitizedMarker] = true;
    return result;
  }
  
  /// Removes the sanitization marker from the data
  static Map<String, dynamic> removeSanitizationMarker(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    result.remove(sanitizedMarker);
    
    // Recursively remove markers from nested maps
    result.forEach((key, value) {
      if (value is Map<String, dynamic> && value.containsKey(sanitizedMarker)) {
        result[key] = removeSanitizationMarker(value);
      }
    });
    
    return result;
  }

  /// Sanitizes a string by only anonymizing zipcodes, preserving the first 3 digits
  static String sanitizeString(String input, {String? fieldName}) {
    if (input.isEmpty) return input;
    
    // Special handling for zipcode fields
    if (fieldName != null) {
      // If this is a zipcode field but not already anonymized
      if ((fieldName == 'zipcode' || fieldName == 'zip' || fieldName == 'postal_code' || 
          fieldName == 'region_code') &&
          !input.endsWith('XX') && 
          RegExp(r'^\d{5}$').hasMatch(input)) {
        // Only keep first 3 digits of zipcode for anonymity
        return '${input.substring(0, 3)}XX';
      }
    }
    
    // For zipcode patterns found in regular text, also preserve first 3 digits
    String result = input;
    
    // Handle standard 5-digit US zipcodes
    result = result.replaceAllMapped(
      RegExp(r'\b(\d{3})\d{2}\b'), 
      (match) => '${match.group(1)}XX',
    );
    
    return result;
  }
  
  /// Sanitizes a map of key-value pairs by applying zipcode sanitization to string values
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> map) {
    // Skip if already sanitized
    if (isAlreadySanitized(map)) {
      return removeSanitizationMarker(map);
    }
    
    final sanitizedMap = <String, dynamic>{};
    
    // Apply sanitization to all string values
    map.forEach((key, value) {
      if (value is String) {
        sanitizedMap[key] = sanitizeString(value, fieldName: key);
      } else if (value is Map) {
        sanitizedMap[key] = sanitizeMap(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitizedMap[key] = sanitizeList(value);
      } else {
        sanitizedMap[key] = value;
      }
    });
    
    // Mark the map as sanitized to prevent double sanitization
    return markAsSanitized(sanitizedMap);
  }
  
  /// Sanitizes a list by applying zipcode sanitization to string values
  static List<dynamic> sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return sanitizeString(item);
      } else if (item is Map) {
        return sanitizeMap(Map<String, dynamic>.from(item));
      } else if (item is List) {
        return sanitizeList(item);
      }
      return item;
    }).toList();
  }
  
  /// Sanitizes analytics parameters for safe logging
  /// Use this method for sanitizing Firebase Analytics parameters
  static Map<String, Object?> sanitizeAnalyticsParams(Map<String, Object?> params) {
    // Process as a dynamic map and then convert back
    final dynamicMap = Map<String, dynamic>.from(params);
    final sanitizedDynamic = sanitizeMap(dynamicMap);
    
    // Remove the sanitization marker before returning
    return removeSanitizationMarker(sanitizedDynamic);
  }
} 
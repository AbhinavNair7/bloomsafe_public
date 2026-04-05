import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:bloomsafe/core/services/security_service.dart';
import 'package:bloomsafe/core/config/secure_storage.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Implementation of SecurityService that performs security audits and validation
class SecurityServiceImpl implements SecurityService {

  /// Factory constructor for singleton
  factory SecurityServiceImpl() => _instance;

  /// Private constructor for singleton
  SecurityServiceImpl._internal();
  /// Singleton instance
  static final SecurityServiceImpl _instance = SecurityServiceImpl._internal();

  /// Flag to indicate if running in an emulator
  bool? _isEmulator;
  
  /// Device info plugin instance
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// The secure storage instance for checking
  final SecureStorage _secureStorage = SecureStorage();

  @override
  Future<List<SecurityVulnerability>> runSecurityScan({
    SecurityScanType scanType = SecurityScanType.all,
  }) async {
    final List<SecurityVulnerability> vulnerabilities = [];

    if (scanType == SecurityScanType.dataStorage ||
        scanType == SecurityScanType.all) {
      vulnerabilities.addAll(await validateDataStorageSecurity());
    }

    if (scanType == SecurityScanType.apiCommunication ||
        scanType == SecurityScanType.all) {
      vulnerabilities.addAll(await validateApiCommunicationSecurity());
    }

    if (scanType == SecurityScanType.encryption ||
        scanType == SecurityScanType.all) {
      vulnerabilities.addAll(await validateEncryptionSecurity());
    }

    if (scanType == SecurityScanType.authentication ||
        scanType == SecurityScanType.all) {
      vulnerabilities.addAll(await validateAuthenticationSecurity());
    }

    // Check for emulator/simulator
    if (await isRunningInEmulator()) {
      vulnerabilities.add(
        SecurityVulnerability(
          type: 'environment',
          description: 'App is running in an emulator or simulator',
          severity: 'medium',
          recommendation:
              'Sensitive operations should be restricted in emulator/simulator',
          location: 'device',
        ),
      );
    }

    // Check for device security
    if (!await isDeviceSecure()) {
      vulnerabilities.add(
        SecurityVulnerability(
          type: 'device',
          description: 'Device has security vulnerabilities',
          severity: 'high',
          recommendation:
              'Consider implementing additional security measures for compromised devices',
          location: 'device',
        ),
      );
    }

    return vulnerabilities;
  }

  @override
  Future<List<SecurityVulnerability>> validateDataStorageSecurity() async {
    final List<SecurityVulnerability> vulnerabilities = [];

    try {
      // Check if secure storage is used
      final secureStorage = const FlutterSecureStorage();
      // Try a simple write/read operation to verify secure storage works
      await secureStorage.write(key: 'security_test', value: 'test');
      final testValue = await secureStorage.read(key: 'security_test');
      await secureStorage.delete(key: 'security_test');

      if (testValue != 'test') {
        vulnerabilities.add(
          SecurityVulnerability(
            type: 'secure_storage',
            description: 'FlutterSecureStorage not working properly',
            severity: 'high',
            recommendation: 'Verify that secure storage is properly configured',
            location: 'lib/core/config/secure_storage.dart',
          ),
        );
      }

      // Check for SharedPreferences usage (could still be in the code)
      // Note: This is just a static check, as we can't actually check for SP instances
      vulnerabilities.add(
        SecurityVulnerability(
          type: 'shared_preferences',
          description:
              'Audit needed: Verify all sensitive data is stored in secure storage',
          severity: 'medium',
          recommendation:
              'Review codebase to ensure no sensitive data is stored in SharedPreferences',
          location: 'codebase',
        ),
      );
    } catch (e) {
      vulnerabilities.add(
        SecurityVulnerability(
          type: 'secure_storage',
          description: 'Error validating secure storage: $e',
          severity: 'high',
          recommendation:
              'Verify secure storage configuration and error handling',
          location: 'lib/core/config/secure_storage.dart',
        ),
      );
    }

    return vulnerabilities;
  }

  @override
  Future<List<SecurityVulnerability>> validateApiCommunicationSecurity() async {
    final List<SecurityVulnerability> vulnerabilities = [];

    // Check if certificate pinning is implemented
    vulnerabilities.add(
      SecurityVulnerability(
        type: 'certificate_pinning',
        description: 'Audit needed: Verify certificate pinning implementation',
        severity: 'medium',
        recommendation:
            'Implement certificate pinning for production API endpoints',
        location: 'lib/core/network/api_client.dart',
      ),
    );

    // Check for HTTPS usage
    vulnerabilities.add(
      SecurityVulnerability(
        type: 'https',
        description: 'Audit needed: Verify all API endpoints use HTTPS',
        severity: 'high',
        recommendation:
            'Ensure all API endpoints use HTTPS with proper SSL/TLS configuration',
        location: 'lib/core/network/api_client.dart',
      ),
    );

    return vulnerabilities;
  }

  @override
  Future<List<SecurityVulnerability>> validateEncryptionSecurity() async {
    final List<SecurityVulnerability> vulnerabilities = [];

    // Check for encryption of sensitive user data
    vulnerabilities.add(
      SecurityVulnerability(
        type: 'data_encryption',
        description:
            'Audit needed: Verify encryption of all sensitive user data',
        severity: 'high',
        recommendation:
            'Implement encryption utilities for all sensitive user data',
        location: 'lib/core/utils',
      ),
    );

    return vulnerabilities;
  }

  @override
  Future<List<SecurityVulnerability>> validateAuthenticationSecurity() async {
    // For BloomSafe, this is less relevant as it doesn't have user authentication
    // but we'll keep the interface method for future enhancements
    return [];
  }

  @override
  Future<bool> isDeviceSecure() async {
    try {
      if (Platform.isAndroid) {
        // Check for Android device security
        return await _isAndroidDeviceSecure();
      } else if (Platform.isIOS) {
        // Check for iOS device security
        return await _isIOSDeviceSecure();
      }

      // Default to true for unsupported platforms
      return true;
    } catch (e) {
      Logger.error('Error checking device security: $e');
      // If there's an error, assume device is secure to avoid false positives
      return true;
    }
  }
  
  /// Check if Android device is secure
  Future<bool> _isAndroidDeviceSecure() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      // List of potentially insecure build tags
      final List<String> insecureBuildTags = [
        'test-keys', // Often indicates a custom ROM
        'dev-keys',  // Development keys
      ];
      
      // Check if the device is potentially rooted
      final buildTags = androidInfo.tags;
      final fingerprint = androidInfo.fingerprint;
      final manufacturer = androidInfo.manufacturer;
      final model = androidInfo.model;
      
      // Known rooted device manufacturers/models
      final isKnownRootedDevice = 
          manufacturer.toLowerCase() == 'genymotion' ||
          model.toLowerCase().contains('google_sdk');
      
      // Check for signs of rooting
      final hasPotentialRootSignatures = 
          insecureBuildTags.any((tag) => buildTags.contains(tag));
      
      // Check for emulator indicators
      final isProbablyEmulator = await isRunningInEmulator();
      
      // Log device info in debug mode
      if (kDebugMode) {
        Logger.debug('Android security check:');
        Logger.debug('  • Build tags: $buildTags');
        Logger.debug('  • Fingerprint: $fingerprint');
        Logger.debug('  • Manufacturer: $manufacturer');
        Logger.debug('  • Model: $model');
        Logger.debug('  • Has root signatures: $hasPotentialRootSignatures');
        Logger.debug('  • Is emulator: $isProbablyEmulator');
      }
      
      return !(hasPotentialRootSignatures || isKnownRootedDevice);
    } catch (e) {
      Logger.error('Error checking Android device security: $e');
      return true; // Assume secure on error
    }
  }
  
  /// Check if iOS device is secure
  Future<bool> _isIOSDeviceSecure() async {
    try {
      final iosInfo = await _deviceInfo.iosInfo;
      
      // Check for simulator
      final isProbablySimulator = await isRunningInEmulator();
      
      // iOS jailbreak detection is complex and can be circumvented
      // This is a basic check, but not foolproof
      final isJailbroken = _isIOSJailbroken(iosInfo);
      
      // Log device info in debug mode
      if (kDebugMode) {
        Logger.debug('iOS security check:');
        Logger.debug('  • Name: ${iosInfo.name}');
        Logger.debug('  • System name: ${iosInfo.systemName}');
        Logger.debug('  • System version: ${iosInfo.systemVersion}');
        Logger.debug('  • Model: ${iosInfo.model}');
        Logger.debug('  • Is simulator: $isProbablySimulator');
        Logger.debug('  • Potentially jailbroken: $isJailbroken');
      }
      
      return !(isJailbroken || isProbablySimulator);
    } catch (e) {
      Logger.error('Error checking iOS device security: $e');
      return true; // Assume secure on error
    }
  }
  
  /// Check for signs of jailbreak on iOS
  bool _isIOSJailbroken(IosDeviceInfo iosInfo) {
    // On real devices, utsname.version contains firmware information
    // On jailbroken devices, this might be modified
    final model = iosInfo.model.toLowerCase();
    final systemName = iosInfo.systemName.toLowerCase();
    
    // These are basic checks and can be bypassed by sophisticated jailbreaks
    return model.contains('simulator') || 
           systemName != 'ios';
  }

  @override
  Future<bool> isRunningInEmulator() async {
    // Cache the result to avoid repeated checks
    if (_isEmulator != null) {
      return _isEmulator!;
    }

    try {
      if (Platform.isAndroid) {
        _isEmulator = await _isAndroidEmulator();
      } else if (Platform.isIOS) {
        _isEmulator = await _isIOSSimulator();
      } else {
        _isEmulator = false;
      }

      return _isEmulator!;
    } catch (e) {
      Logger.error('Error checking emulator status: $e');
      // If there's an error, assume it's not an emulator
      _isEmulator = false;
      return false;
    }
  }
  
  /// Check if running on Android emulator
  Future<bool> _isAndroidEmulator() async {
    final androidInfo = await _deviceInfo.androidInfo;
    
    // Common emulator characteristics
    return androidInfo.isPhysicalDevice == false || 
           androidInfo.model.toLowerCase().contains('emulator') ||
           androidInfo.model.toLowerCase().contains('sdk') ||
           androidInfo.model.toLowerCase().contains('simulator') ||
           androidInfo.brand.toLowerCase().contains('google') && 
              androidInfo.model.toLowerCase().contains('sdk') ||
           androidInfo.manufacturer.toLowerCase().contains('genymotion');
  }
  
  /// Check if running on iOS simulator
  Future<bool> _isIOSSimulator() async {
    final iosInfo = await _deviceInfo.iosInfo;
    
    // iOS simulators are not physical devices
    return iosInfo.isPhysicalDevice == false || 
           iosInfo.model.toLowerCase().contains('simulator');
  }

  @override
  Future<Map<String, bool>> getSecuritySummary() async {
    final Map<String, bool> summary = {};

    // Run each validation and summarize results
    summary['data_storage'] = (await validateDataStorageSecurity()).isEmpty;
    summary['api_communication'] =
        (await validateApiCommunicationSecurity()).isEmpty;
    summary['encryption'] = (await validateEncryptionSecurity()).isEmpty;
    summary['device_security'] = await isDeviceSecure();
    summary['not_emulator'] = !(await isRunningInEmulator());

    return summary;
  }
}

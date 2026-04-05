
enum SecurityScanType {
  dataStorage,
  apiCommunication,
  encryption,
  authentication,
  all,
}

class SecurityVulnerability { // file or component where vulnerability was found

  SecurityVulnerability({
    required this.type,
    required this.description,
    required this.severity,
    this.recommendation,
    this.location,
  });
  final String type;
  final String description;
  final String severity; // 'high', 'medium', 'low'
  final String? recommendation;
  final String? location;

  @override
  String toString() {
    return 'SecurityVulnerability{type: $type, severity: $severity, description: $description}';
  }
}

/// Interface for the SecurityService that provides security auditing and validation
abstract class SecurityService {
  /// Run a security scan on the app based on the specified scan type
  /// Returns a list of security vulnerabilities found
  Future<List<SecurityVulnerability>> runSecurityScan({
    SecurityScanType scanType = SecurityScanType.all,
  });

  /// Validate the security of data storage mechanisms
  /// Returns a list of security vulnerabilities found in storage implementations
  Future<List<SecurityVulnerability>> validateDataStorageSecurity();

  /// Validate that API communications are secure (HTTPS, certificate validation, etc.)
  /// Returns a list of security vulnerabilities found in API communications
  Future<List<SecurityVulnerability>> validateApiCommunicationSecurity();

  /// Validate encryption implementations for sensitive data
  /// Returns a list of security vulnerabilities found in encryption implementations
  Future<List<SecurityVulnerability>> validateEncryptionSecurity();

  /// Validate authentication mechanisms
  /// Returns a list of security vulnerabilities found in authentication mechanisms
  Future<List<SecurityVulnerability>> validateAuthenticationSecurity();

  /// Check if the device has any security vulnerabilities
  /// (e.g., is rooted/jailbroken, has outdated OS, etc.)
  /// Returns true if the device is secure, false otherwise
  Future<bool> isDeviceSecure();

  /// Check if the app is running in an emulator or simulator
  /// This is useful for preventing sensitive operations in unsecured environments
  Future<bool> isRunningInEmulator();

  /// Get a summary of the security status of the app
  /// Returns a map of security component names to their status (true = secure)
  Future<Map<String, bool>> getSecuritySummary();
}

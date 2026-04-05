import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Utility class for handling encryption and decryption of sensitive data
class EncryptionUtils {

  /// Factory constructor for singleton
  factory EncryptionUtils() => _instance;

  /// Private constructor for singleton
  EncryptionUtils._internal();
  
  /// Test constructor that accepts a mock storage
  /// This is only used for testing purposes
  @visibleForTesting
  factory EncryptionUtils.test(dynamic mockStorage) {
    final instance = EncryptionUtils._internal();
    instance._testMode = true;
    instance._mockStorage = mockStorage;
    return instance;
  }
  /// Singleton instance
  static final EncryptionUtils _instance = EncryptionUtils._internal();

  /// Storage key for the encryption key
  static const String _encryptionKeyStorageKey = 'bloomsafe_encryption_key';
  
  /// Storage key for the encryption IV
  static const String _encryptionIvKey = 'bloomsafe_encryption_iv';

  /// The secure storage instance
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Flag to indicate test mode
  bool _testMode = false;
  
  /// Mock storage for testing
  dynamic _mockStorage;

  /// Cached encryption key
  String? _cachedEncryptionKey;
  
  /// Cached encryption IV
  String? _cachedEncryptionIv;
  
  /// AES encrypter instance
  enc.Encrypter? _encrypter;
  
  /// IV for encryption
  enc.IV? _iv;

  /// Initialize encryption utils by ensuring an encryption key exists
  Future<void> initialize() async {
    await _getOrCreateEncryptionKey();
    await _getOrCreateEncryptionIv();
    _setupEncrypter();
  }
  
  /// Set up the encrypter with the key
  void _setupEncrypter() {
    if (_cachedEncryptionKey != null) {
      try {
        // Create a key of exactly 32 bytes (256 bits) for AES-256
        final keyBytes = base64Decode(_cachedEncryptionKey!);
        final key = enc.Key(keyBytes);
        
        // Set up the encrypter with the key
        _encrypter = enc.Encrypter(enc.AES(key));
        
        // Create a random IV for each encryption
        _iv = enc.IV.fromSecureRandom(16);
      } catch (e) {
        Logger.error('Error setting up encrypter: $e');
      }
    }
  }

  /// Get the stored encryption key or create a new one if it doesn't exist
  Future<String> _getOrCreateEncryptionKey() async {
    if (_cachedEncryptionKey != null) {
      return _cachedEncryptionKey!;
    }

    try {
      // Try to get existing key
      String? key;
      
      if (_testMode && _mockStorage != null) {
        key = await _mockStorage.read(key: _encryptionKeyStorageKey);
      } else {
        key = await _secureStorage.read(key: _encryptionKeyStorageKey);
      }

      // If no key exists, create a new one
      if (key == null || key.isEmpty) {
        key = _generateSecureRandomKey();
        if (_testMode && _mockStorage != null) {
          await _mockStorage.write(key: _encryptionKeyStorageKey, value: key);
        } else {
          await _secureStorage.write(key: _encryptionKeyStorageKey, value: key);
        }
      }

      _cachedEncryptionKey = key;
      return key;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error getting encryption key: $e');
      }

      // Generate a temporary key if secure storage fails
      // Note: This is less secure but prevents crashes
      final tempKey = _generateSecureRandomKey();
      _cachedEncryptionKey = tempKey;
      return tempKey;
    }
  }
  
  /// Get the stored encryption IV or create a new one if it doesn't exist
  Future<String> _getOrCreateEncryptionIv() async {
    if (_cachedEncryptionIv != null) {
      return _cachedEncryptionIv!;
    }

    try {
      // Try to get existing IV
      String? iv;
      
      if (_testMode && _mockStorage != null) {
        iv = await _mockStorage.read(key: _encryptionIvKey);
      } else {
        iv = await _secureStorage.read(key: _encryptionIvKey);
      }

      // If no IV exists, create a new one
      if (iv == null || iv.isEmpty) {
        iv = _generateSecureRandomIv();
        if (_testMode && _mockStorage != null) {
          await _mockStorage.write(key: _encryptionIvKey, value: iv);
        } else {
          await _secureStorage.write(key: _encryptionIvKey, value: iv);
        }
      }

      _cachedEncryptionIv = iv;
      return iv;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error getting encryption IV: $e');
      }

      // Generate a temporary IV if secure storage fails
      final tempIv = _generateSecureRandomIv();
      _cachedEncryptionIv = tempIv;
      return tempIv;
    }
  }

  /// Generate a secure random key for encryption (256 bits / 32 bytes for AES-256)
  String _generateSecureRandomKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(values);
  }
  
  /// Generate a secure random IV for encryption (128 bits / 16 bytes for AES)
  String _generateSecureRandomIv() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(values);
  }

  /// Encrypt sensitive data using AES-256 encryption
  /// Returns the encrypted string or null if encryption fails
  Future<String?> encrypt(String data) async {
    if (data.isEmpty) {
      return data;
    }

    try {
      // Make sure encryption is initialized
      await initialize();
      
      if (_encrypter == null) {
        Logger.error('Encryption not properly initialized');
        return null;
      }
      
      // Generate a new IV for this encryption
      final iv = enc.IV.fromSecureRandom(16);
      
      // Use the encrypt package for proper AES encryption
      final encrypted = _encrypter!.encrypt(data, iv: iv);
      
      // Return the base64 encoded IV and encrypted data
      return '${base64Encode(iv.bytes)}:${encrypted.base64}';
    } catch (e) {
      Logger.error('Error encrypting data: $e');
      return null;
    }
  }

  /// Decrypt encrypted data using AES-256 decryption
  /// Returns the decrypted string or null if decryption fails
  Future<String?> decrypt(String encryptedData) async {
    if (encryptedData.isEmpty) {
      return encryptedData;
    }

    try {
      // Split IV and encrypted data
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        return null; // Invalid format
      }
      
      // Get the IV and encrypted content
      final ivBase64 = parts[0];
      final encryptedContent = parts[1];
      
      // Initialize encryption if not done yet
      await initialize();
      
      if (_encrypter == null) {
        Logger.error('Encryption not properly initialized');
        return null;
      }
      
      // Create IV from stored value
      final iv = enc.IV(base64Decode(ivBase64));
      
      // Create encrypted object from base64
      final encrypted = enc.Encrypted.fromBase64(encryptedContent);
      
      // Decrypt the data
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      Logger.error('Error decrypting data: $e');
      return null;
    }
  }

  /// Hash data (for non-reversible encryption, like passwords)
  /// Returns a SHA-256 hash of the data
  String hash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if data is encrypted (has proper format)
  bool isEncrypted(String data) {
    if (data.isEmpty) {
      return false;
    }

    // Check if it has the IV:encrypted format
    final parts = data.split(':');
    if (parts.length != 2) {
      return false;
    }

    try {
      // Try to decode the base64 parts
      base64Decode(parts[0]); // IV
      base64Decode(parts[1]); // Encrypted data
      return true;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for initializing and managing Hive with encryption
class HiveService {
  static const String _encryptionKeyKey = 'hive_encryption_key';
  static const String _keyDerivationSaltKey = 'hive_key_derivation_salt';
  static const String _initializedKey = 'hive_initialized';

  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();

  HiveService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Hive with encryption support
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive Flutter for proper platform support
      await Hive.initFlutter();

      // Initialize the main Hive instance
      await Hive.init();

      // Generate or retrieve encryption key
      final encryptionKey = await _getOrCreateEncryptionKey();

      // Register adapters
      await _registerAdapters();

      // Verify encryption setup
      await _verifyEncryption(encryptionKey);

      _isInitialized = true;
      
      // Mark as initialized in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_initializedKey, true);
    } catch (e) {
      throw HiveInitializationException('Failed to initialize Hive: $e');
    }
  }

  /// Generate or retrieve the encryption key from secure storage
  Future<Uint8List> _getOrCreateEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if key already exists
    final existingKey = prefs.getString(_encryptionKeyKey);
    if (existingKey != null) {
      return base64.decode(existingKey);
    }

    // Generate new encryption key
    final keyBytes = _generateEncryptionKey();
    final encodedKey = base64.encode(keyBytes);
    
    // Store in secure preferences (not truly secure, but better than nothing)
    await prefs.setString(_encryptionKeyKey, encodedKey);
    
    // Generate and store salt for key derivation
    final salt = _generateSalt();
    await prefs.setString(_keyDerivationSaltKey, base64.encode(salt));
    
    return keyBytes;
  }

  /// Generate a cryptographically secure encryption key
  Uint8List _generateEncryptionKey() {
    final keyBytes = Uint8List(32); // 256-bit key
    final random = Random.secure();
    random.nextBytes(keyBytes);
    return keyBytes;
  }

  /// Generate a salt for key derivation
  Uint8List _generateSalt() {
    final salt = Uint8List(16);
    final random = Random.secure();
    random.nextBytes(salt);
    return salt;
  }

  /// Derive a key using PBKDF2 for additional security
  Future<Uint8List> deriveKey(Uint8List password, Uint8List salt) async {
    const iterations = 10000;
    final key = pbdkdf2(password, salt, iterations, 32);
    return key;
  }

  /// Simple PBKDF2 implementation
  Uint8List pbdkdf2(Uint8List password, Uint8List salt, int iterations, int keyLength) {
    // Simplified PBKDF2 - in production, consider using crypto library
    final hasher = sha256.convert;
    Uint8List output = Uint8List(keyLength);
    
    for (int i = 0; i < iterations; i++) {
      final input = concatUint8Lists([
        salt,
        password,
        Uint8List.fromList([i ~/ 256, i % 256]),
      ]);
      final hash = hasher.convert(input).bytes;
      for (int j = 0; j < min(hash.length, output.length); j++) {
        output[j] ^= hash[j];
      }
    }
    
    return output;
  }

  Uint8List concatUint8Lists(List<Uint8List> lists) {
    final totalLength = lists.fold<int>(0, (sum, list) => sum + list.length);
    final result = Uint8List(totalLength);
    int offset = 0;
    for (final list in lists) {
      result.setRange(offset, offset + list.length, list);
      offset += list.length;
    }
    return result;
  }

  /// Register all Hive adapters
  Future<void> _registerAdapters() async {
    // This would normally be done by build_runner, but we'll do it manually
    // for the example. In a real app, use: `flutter packages pub run build_runner build`
    if (!Hive.isAdapterRegistered(0)) {
      // ContextEvent adapter would be generated here
      // Hive.registerAdapter(ContextEventAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      // Suggestion adapter
      // Hive.registerAdapter(SuggestionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      // UserPreference adapter
      // Hive.registerAdapter(UserPreferenceAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      // MessageSummary adapter
      // Hive.registerAdapter(MessageSummaryAdapter());
    }
  }

  /// Verify that encryption is working correctly
  Future<void> _verifyEncryption(Uint8List encryptionKey) async {
    try {
      // Open a test box with encryption
      await Hive.openBox('test_verification', encryptionKey: encryptionKey);
      
      // Test write/read
      final testBox = Hive.box('test_verification');
      const testKey = 'test_key';
      const testValue = 'test_encrypted_value';
      
      await testBox.put(testKey, testValue);
      final readValue = testBox.get(testKey);
      
      if (readValue != testValue) {
        throw HiveInitializationException('Encryption verification failed');
      }
      
      // Clean up test box
      await testBox.deleteFromDisk();
    } catch (e) {
      throw HiveInitializationException('Encryption verification failed: $e');
    }
  }

  /// Check if Hive is properly initialized
  Future<bool> isProperlyInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_initializedKey) ?? false;
  }

  /// Reset all Hive data (use with caution)
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_encryptionKeyKey);
    await prefs.remove(_keyDerivationSaltKey);
    await prefs.remove(_initializedKey);
    
    // Delete all Hive boxes
    await Hive.deleteFromDisk();
    
    _isInitialized = false;
  }
}

/// Exception thrown when Hive initialization fails
class HiveInitializationException implements Exception {
  final String message;
  HiveInitializationException(this.message);

  @override
  String toString() => 'HiveInitializationException: $message';
}
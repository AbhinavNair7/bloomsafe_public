import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/services/discord_service.dart';

void main() {
  late DiscordService discordService;

  setUp(() {
    discordService = DiscordService();
  });

  group('DiscordService', () {
    test('isWebhookConfigured returns false when webhook URL is null', () {
      // A fresh instance should have no webhook configured
      expect(discordService.isWebhookConfigured(), isFalse);
    });

    test('initializeWithUrl sets the webhook URL', () async {
      // Arrange
      const testUrl = 'https://discord.com/api/webhooks/test';
      
      // Act
      await discordService.initializeWithUrl(testUrl);
      
      // Assert
      expect(discordService.isWebhookConfigured(), isTrue);
    });

    test('initialize with URL succeeds', () async {
      // Arrange
      const testUrl = 'https://discord.com/api/webhooks/test';
      
      // Act
      await discordService.initializeWithUrl(testUrl);
      
      // Assert
      expect(discordService.isWebhookConfigured(), isTrue);
    });
  });
} 
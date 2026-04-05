// API rate limiting
const int maxSearchesPerMinute =
    5; // Maximum allowed searches per minute (default)
const int rateLimitCooldownMinutes =
    10; // Cooldown period after hitting rate limit

// General API timeouts
const Duration defaultConnectTimeout = Duration(
  seconds: 10,
); // Default connection timeout for API requests
const Duration defaultReceiveTimeout = Duration(
  seconds: 15,
); // Default receive timeout for API requests

// Note for developers: Rate limiting is applied to all API calls regardless of endpoint

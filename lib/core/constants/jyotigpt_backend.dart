/// Backend configuration for the consumer JyotiGPT app.
///
/// The API shape matches Open-WebUI; only the base URL is fixed.
library;

/// Fixed API base URL for all requests.
const String kJyotiGPTApiBaseUrl = 'https://jyotigpt.us.to/';

/// Stable identifier used for cache scoping.
const String kJyotiGPTServerId = 'jyotigpt-prod';

/// Display name used in internal config objects.
const String kJyotiGPTServerName = 'JyotiGPT';


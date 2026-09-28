enum AvailabilityStatus {
  available,
  limited,
  soldOut,
  unavailable,
  unknown;

  static AvailabilityStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'AVAILABLE':
        return AvailabilityStatus.available;
      case 'LIMITED':
        return AvailabilityStatus.limited;
      case 'SOLD_OUT':
      case 'SOLDOUT':
        return AvailabilityStatus.soldOut;
      case 'UNAVAILABLE':
        return AvailabilityStatus.unavailable;
      default:
        return AvailabilityStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case AvailabilityStatus.available:
        return 'Available';
      case AvailabilityStatus.limited:
        return 'Limited Availability';
      case AvailabilityStatus.soldOut:
        return 'Sold Out';
      case AvailabilityStatus.unavailable:
        return 'Unavailable';
      case AvailabilityStatus.unknown:
        return 'Check Availability';
    }
  }
}

enum AvailabilityFreshness {
  fresh,
  stale,
  expired,
  unknown;

  static AvailabilityFreshness fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'FRESH':
        return AvailabilityFreshness.fresh;
      case 'STALE':
        return AvailabilityFreshness.stale;
      case 'EXPIRED':
        return AvailabilityFreshness.expired;
      default:
        return AvailabilityFreshness.unknown;
    }
  }
}

class AvailabilityInfo {
  final AvailabilityStatus status;
  final AvailabilityFreshness freshness;
  final int? remainingQuantity;
  final int? totalCapacity;
  final String source;
  final DateTime? lastUpdatedAt;

  const AvailabilityInfo({
    required this.status,
    required this.freshness,
    this.remainingQuantity,
    this.totalCapacity,
    required this.source,
    this.lastUpdatedAt,
  });

  factory AvailabilityInfo.fromJson(Map<String, dynamic> json) {
    return AvailabilityInfo(
      status: AvailabilityStatus.fromString(json['status'] as String?),
      freshness: AvailabilityFreshness.fromString(json['freshness'] as String?),
      remainingQuantity: json['remainingQuantity'] as int?,
      totalCapacity: json['totalCapacity'] as int?,
      source: json['source'] as String? ?? 'SYSTEM',
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.tryParse(json['lastUpdatedAt'].toString())
          : null,
    );
  }
}

class IntegrationProviderInfo {
  final String providerId;
  final String providerName;
  final String providerType;
  final String vertical;
  final bool isConfigured;
  final bool isEnabled;
  final String status;
  final DateTime? lastSyncedAt;
  final String? errorSummary;

  const IntegrationProviderInfo({
    required this.providerId,
    required this.providerName,
    required this.providerType,
    required this.vertical,
    required this.isConfigured,
    required this.isEnabled,
    required this.status,
    this.lastSyncedAt,
    this.errorSummary,
  });

  factory IntegrationProviderInfo.fromJson(Map<String, dynamic> json) {
    return IntegrationProviderInfo(
      providerId: json['providerId'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      providerType: json['providerType'] as String? ?? '',
      vertical: json['vertical'] as String? ?? '',
      isConfigured: json['isConfigured'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? false,
      status: json['status'] as String? ?? 'UNCONFIGURED',
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'].toString())
          : null,
      errorSummary: json['errorSummary'] as String?,
    );
  }
}

class IntegrationSyncRun {
  final String id;
  final String provider;
  final String vertical;
  final String status;
  final int recordsRead;
  final int recordsCreated;
  final int recordsUpdated;
  final int recordsFailed;
  final String? errorSummary;
  final DateTime startedAt;
  final DateTime? completedAt;

  const IntegrationSyncRun({
    required this.id,
    required this.provider,
    required this.vertical,
    required this.status,
    required this.recordsRead,
    required this.recordsCreated,
    required this.recordsUpdated,
    required this.recordsFailed,
    this.errorSummary,
    required this.startedAt,
    this.completedAt,
  });

  factory IntegrationSyncRun.fromJson(Map<String, dynamic> json) {
    return IntegrationSyncRun(
      id: json['id'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      vertical: json['vertical'] as String? ?? '',
      status: json['status'] as String? ?? 'IN_PROGRESS',
      recordsRead: json['recordsRead'] as int? ?? 0,
      recordsCreated: json['recordsCreated'] as int? ?? 0,
      recordsUpdated: json['recordsUpdated'] as int? ?? 0,
      recordsFailed: json['recordsFailed'] as int? ?? 0,
      errorSummary: json['errorSummary'] as String?,
      startedAt: DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }
}

class IntegrationHealthSummary {
  final String status;
  final int totalProviders;
  final int activeProviders;
  final int configuredProviders;
  final int unconfiguredProviders;
  final List<IntegrationSyncRun> recentSyncRuns;

  const IntegrationHealthSummary({
    required this.status,
    required this.totalProviders,
    required this.activeProviders,
    required this.configuredProviders,
    required this.unconfiguredProviders,
    required this.recentSyncRuns,
  });

  factory IntegrationHealthSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final runsJson = json['recentSyncRuns'] as List<dynamic>? ?? [];

    return IntegrationHealthSummary(
      status: json['status'] as String? ?? 'HEALTHY',
      totalProviders: summary['totalProviders'] as int? ?? 0,
      activeProviders: summary['activeProviders'] as int? ?? 0,
      configuredProviders: summary['configuredProviders'] as int? ?? 0,
      unconfiguredProviders: summary['unconfiguredProviders'] as int? ?? 0,
      recentSyncRuns: runsJson
          .map((r) => IntegrationSyncRun.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

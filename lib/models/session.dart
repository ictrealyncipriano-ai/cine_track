class Session {
  final int id;
  final String createdAt;
  final String expiresAt;
  final String? lastUsedAt;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic>? deviceInfo;
  final bool isCurrent;
  final bool isExpired;
  final bool rememberMe;

  const Session({
    required this.id,
    required this.createdAt,
    required this.expiresAt,
    this.lastUsedAt,
    required this.ipAddress,
    required this.userAgent,
    this.deviceInfo,
    required this.isCurrent,
    required this.isExpired,
    this.rememberMe = false,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int,
      createdAt: json['created_at'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
      lastUsedAt: json['last_used_at'] as String?,
      ipAddress: json['ip_address'] as String? ?? '',
      userAgent: json['user_agent'] as String? ?? '',
      deviceInfo: json['device_info'] is Map<String, dynamic> ? json['device_info'] as Map<String, dynamic> : null,
      isCurrent: json['is_current'] == true,
      isExpired: json['is_expired'] == true,
      rememberMe: json['remember_me'] == true,
    );
  }

  String get friendlyName {
    if (isCurrent) return 'Current session';
    if (deviceInfo != null) {
      final platform = deviceInfo!['platform'] as String? ?? '';
      final model = deviceInfo!['model'] as String? ?? '';
      if (platform.isNotEmpty || model.isNotEmpty) {
        final name = '$platform · $model';
      return name.replaceAll(RegExp(r'^ · | · $'), '');
      }
    }
    if (userAgent.isNotEmpty) {
      return _parseUserAgent(userAgent);
    }
    return 'Session #$id';
  }

  String get deviceIconLabel {
    if (deviceInfo != null) {
      final platform = (deviceInfo!['platform'] as String? ?? '').toLowerCase();
      if (platform.contains('android')) return 'android';
      if (platform.contains('ios') || platform.contains('iphone') || platform.contains('ipad')) return 'ios';
      if (platform.contains('web') || platform.contains('mac') || platform.contains('windows') || platform.contains('linux')) return 'desktop';
    }
    final ua = userAgent.toLowerCase();
    if (ua.contains('android')) return 'android';
    if (ua.contains('iphone') || ua.contains('ipad') || ua.contains('ios')) return 'ios';
    return 'desktop';
  }

  static String _parseUserAgent(String ua) {
    String result = ua;
    final browsers = [
      RegExp(r'(Chrome)\/(\d+)'),
      RegExp(r'(Firefox)\/(\d+)'),
      RegExp(r'(Safari)\/(\d+)'),
      RegExp(r'(Edge)\/(\d+)'),
    ];
    for (final regex in browsers) {
      final match = regex.firstMatch(ua);
      if (match != null) {
        result = '${match.group(1)} ${match.group(2)}';
        break;
      }
    }
    if (ua.contains('Windows')) {
      result += ' · Windows';
    } else if (ua.contains('Mac OS X') || ua.contains('macOS')) {
      result += ' · macOS';
    } else if (ua.contains('Linux') && !ua.contains('Android')) {
      result += ' · Linux';
    } else if (ua.contains('Android')) {
      result += ' · Android';
    } else if (ua.contains('iPhone') || ua.contains('iPad')) {
      result += ' · iOS';
    }
    return result;
  }
}

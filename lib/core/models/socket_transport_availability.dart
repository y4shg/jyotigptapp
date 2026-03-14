class SocketTransportAvailability {
  const SocketTransportAvailability({
    required this.allowPolling,
    required this.allowWebsocketOnly,
  });

  final bool allowPolling;
  final bool allowWebsocketOnly;

  Map<String, dynamic> toJson() {
    return {
      'allowPolling': allowPolling,
      'allowWebsocketOnly': allowWebsocketOnly,
    };
  }

  factory SocketTransportAvailability.fromJson(Map<String, dynamic> json) {
    return SocketTransportAvailability(
      allowPolling: json['allowPolling'] == true,
      allowWebsocketOnly: json['allowWebsocketOnly'] == true,
    );
  }
}

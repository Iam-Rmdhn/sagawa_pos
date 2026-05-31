import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sagawa_pos/core/network/api_client.dart';
import 'package:sagawa_pos/core/network/api_config.dart';

class MenuSyncWebSocketService {
  MenuSyncWebSocketService._();

  static final MenuSyncWebSocketService instance = MenuSyncWebSocketService._();

  final StreamController<int> _menuChangedController =
      StreamController<int>.broadcast();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _pollingTimer;
  int? _lastVersion;
  bool _isConnecting = false;
  bool _isClosedByClient = false;

  Stream<int> get onMenuChanged => _menuChangedController.stream;

  Future<void> connect() async {
    _startPollingFallback();
    if (!ApiConfig.menuSyncWebSocketEnabled) return;
    if (_socket != null || _isConnecting) return;

    _isClosedByClient = false;
    _isConnecting = true;

    try {
      final socket = await WebSocket.connect(
        ApiConfig.menuSyncWebSocket,
      ).timeout(const Duration(seconds: 15));

      _socket = socket;
      _startHeartbeat();
      _socketSubscription = socket.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: true,
      );
    } catch (e) {
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    _isClosedByClient = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _pollingTimer?.cancel();
    await _socketSubscription?.cancel();
    await _socket?.close();
    _socketSubscription = null;
    _socket = null;
  }

  void _handleMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message.toString());
      if (decoded is! Map<String, dynamic>) return;

      final rawVersion = decoded['version'];
      final version = rawVersion is int
          ? rawVersion
          : int.tryParse(rawVersion?.toString() ?? '');
      if (version == null || version <= 0) return;

      final eventType = decoded['type']?.toString();
      _handleVersion(
        version,
        notifyWhenNewer:
            eventType == 'menu_sync_changed' ||
            eventType == 'menu_sync_connected',
      );
    } catch (e) {
      // Ignore malformed server messages; reconnect handles broken sockets.
    }
  }

  void _handleDisconnect() {
    _heartbeatTimer?.cancel();
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!ApiConfig.menuSyncWebSocketEnabled) return;
    if (_isClosedByClient || _reconnectTimer?.isActive == true) return;

    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnectTimer = null;
      connect();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      final socket = _socket;
      if (socket == null) return;
      try {
        socket.add('ping');
      } catch (e) {
        _handleDisconnect();
      }
    });
  }

  void _startPollingFallback() {
    if (_pollingTimer?.isActive == true) return;

    _pollMenuSync();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pollMenuSync();
    });
  }

  Future<void> _pollMenuSync() async {
    if (_isClosedByClient) return;

    try {
      final response = await ApiClient().get(ApiConfig.menuSync);
      final data = response.data;
      if (data is! Map) return;

      final rawVersion = data['version'];
      final version = rawVersion is int
          ? rawVersion
          : int.tryParse(rawVersion?.toString() ?? '');
      if (version == null || version <= 0) return;

      _handleVersion(version, notifyWhenNewer: true);
    } catch (_) {
      // WebSocket remains the primary channel; polling retries on the next tick.
    }
  }

  void _handleVersion(int version, {required bool notifyWhenNewer}) {
    final previousVersion = _lastVersion;
    final isNewer = previousVersion != null && version > previousVersion;

    _lastVersion = version;

    if (notifyWhenNewer && isNewer) {
      _menuChangedController.add(version);
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  int? _lastVersion;
  bool _isConnecting = false;
  bool _isClosedByClient = false;

  Stream<int> get onMenuChanged => _menuChangedController.stream;

  Future<void> connect() async {
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
      final isReconnectWithNewerVersion =
          eventType == 'menu_sync_connected' &&
          _lastVersion != null &&
          version > _lastVersion!;
      final shouldNotify =
          (eventType == 'menu_sync_changed' || isReconnectWithNewerVersion) &&
          (_lastVersion == null || version > _lastVersion!);

      _lastVersion = version;

      if (shouldNotify) {
        _menuChangedController.add(version);
      }
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
}

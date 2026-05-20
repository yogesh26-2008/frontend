import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';
import 'api_service.dart';

/// Singleton chat service — WebSocket + REST.
///
/// BUGS FIXED:
/// 1. getConversations() had a broken ApiService.get() call at the top that
///    ALWAYS threw TypeError (API returns a List, ApiService.get casts to Map).
///    The custom http.get below it NEVER ran. Chat list was always empty.
/// 2. No WebSocket auto-reconnect — dropped connections broke chat forever.
/// 3. No timeout on HTTP calls — could hang indefinitely.
/// 4. Typing events sent on every keystroke — WebSocket spam.
///    Now throttled to once per 2 seconds via sendTyping().
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  WebSocketChannel? _channel;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  int _reconnectDelay = 2; // seconds, doubles each attempt

  final _messageCtrl = StreamController<ChatMessage>.broadcast();
  final _typingCtrl  = StreamController<Map<String, dynamic>>.broadcast();

  // Typing throttle — only send 1 event per 2 seconds
  DateTime? _lastTypingSent;

  Stream<ChatMessage> get messageStream => _messageCtrl.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingCtrl.stream;
  bool get isConnected => _channel != null;

  // ── WebSocket ────────────────────────────────────────────────

  Future<void> connectWebSocket() async {
    if (_channel != null || _isConnecting) return;
    _isConnecting = true;

    final token = await ApiService.getToken();
    if (token == null) { _isConnecting = false; return; }

    final wsUri = Uri.parse('$wsUrl/chat/ws?token=$token');
    developer.log('[ChatService] Connecting WebSocket: $wsUri');

    try {
      _channel = WebSocketChannel.connect(wsUri);

      // Wait for connection to be ready (throws if server rejects)
      await _channel!.ready.timeout(const Duration(seconds: 10));
      _reconnectDelay = 2; // reset backoff on success
      developer.log('[ChatService] WebSocket connected ✓');

      _channel!.stream.listen(
        _onWsMessage,
        onDone: _onWsDone,
        onError: _onWsError,
        cancelOnError: false,
      );
    } catch (e) {
      developer.log('[ChatService] WebSocket connect failed: $e');
      _channel = null;
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _onWsMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'message') {
        final msg = ChatMessage.fromJson(data['message'] as Map<String, dynamic>);
        _messageCtrl.add(msg);
      } else if (type == 'typing') {
        _typingCtrl.add({
          'conversation_id': data['conversation_id'],
          'user_id': data['user_id'],
        });
      }
    } catch (e) {
      developer.log('[ChatService] WS parse error: $e');
    }
  }

  void _onWsDone() {
    developer.log('[ChatService] WebSocket closed — scheduling reconnect');
    _channel = null;
    _scheduleReconnect();
  }

  void _onWsError(Object error) {
    developer.log('[ChatService] WebSocket error: $error');
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = _reconnectDelay;
    _reconnectDelay = (_reconnectDelay * 2).clamp(2, 60); // max 60s
    developer.log('[ChatService] Reconnecting in ${delay}s…');
    _reconnectTimer = Timer(Duration(seconds: delay), connectWebSocket);
  }

  void disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
  }

  // ── Send helpers ─────────────────────────────────────────────

  void sendMessage(String conversationId, String text) {
    if (_channel == null) {
      developer.log('[ChatService] sendMessage: WS not connected');
      return;
    }
    _channel!.sink.add(jsonEncode({
      'type': 'message',
      'conversation_id': conversationId,
      'text': text,
    }));
  }

  /// Throttled — sends at most 1 typing event per 2 seconds.
  void sendTyping(String conversationId) {
    if (_channel == null) return;
    final now = DateTime.now();
    if (_lastTypingSent != null &&
        now.difference(_lastTypingSent!).inSeconds < 2) return;
    _lastTypingSent = now;
    _channel!.sink.add(jsonEncode({
      'type': 'typing',
      'conversation_id': conversationId,
    }));
  }

  void markAsRead(String conversationId) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'read',
      'conversation_id': conversationId,
    }));
  }

  // ── REST endpoints ───────────────────────────────────────────

  /// BUG FIX: Removed the broken ApiService.get() call that was at the top.
  /// ApiService.get() casts the response to Map<String, dynamic>, but
  /// /chat/conversations returns a JSON *array*. That cast always threw a
  /// TypeError, and the correct http.get below it NEVER ran.
  /// Result: chat list was always empty, and _startChat always failed.
  Future<List<ChatConversation>> getConversations() async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/chat/conversations'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body) as List;
      return data
          .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (res.statusCode == 401) {
      await ApiService.clearToken();
      throw const ApiException('Session expired. Please sign in again.');
    } else {
      throw ApiException('Failed to load conversations (${res.statusCode})');
    }
  }

  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/chat/$conversationId/messages?skip=$skip&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body) as List;
      return data
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (res.statusCode == 401) {
      await ApiService.clearToken();
      throw const ApiException('Session expired. Please sign in again.');
    } else {
      throw ApiException('Failed to load messages (${res.statusCode})');
    }
  }

  Future<String> startConversation(String participantUsername) async {
    final response = await ApiService.post(
      '/chat/conversations',
      {'participant_username': participantUsername},
      requiresAuth: true,
    );
    return response['conversation_id'] as String;
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    final token = await ApiService.getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/chat/$conversationId/messages/$messageId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException('Failed to delete message (${res.statusCode})');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final token = await ApiService.getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/chat/$conversationId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException('Failed to delete conversation (${res.statusCode})');
    }
  }
}

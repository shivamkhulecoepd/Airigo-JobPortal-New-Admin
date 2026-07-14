// ============================================================
// core/providers/realtime_updates_provider.dart
// Handles real-time updates and WebSocket connections
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

enum RealtimeEventType {
  jobPosted,
  applicationReceived,
  applicationStatusChanged,
  jobStatusChanged,
  newMessage,
  systemNotification,
}

class RealtimeEvent {
  final RealtimeEventType type;
  final String title;
  final String message;
  final dynamic payload;
  final DateTime timestamp;

  RealtimeEvent({
    required this.type,
    required this.title,
    required this.message,
    this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeEvent(
      type: RealtimeEventType.values.byName(json['type'] ?? 'systemNotification'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      payload: json['payload'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'title': title,
      'message': message,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

final realtimeUpdatesProvider =
    AsyncNotifierProvider<RealtimeUpdatesNotifier, RealtimeUpdatesData>(
  () => RealtimeUpdatesNotifier(),
);

class RealtimeUpdatesData {
  final bool isConnected;
  final List<RealtimeEvent> events;
  final int unreadCount;

  RealtimeUpdatesData({
    this.isConnected = false,
    this.events = const [],
    this.unreadCount = 0,
  });

  RealtimeUpdatesData copyWith({
    bool? isConnected,
    List<RealtimeEvent>? events,
    int? unreadCount,
  }) {
    return RealtimeUpdatesData(
      isConnected: isConnected ?? this.isConnected,
      events: events ?? this.events,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class RealtimeUpdatesNotifier extends AsyncNotifier<RealtimeUpdatesData> {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const String _websocketUrl = 'ws://localhost:8080/ws'; // Replace with your actual WebSocket URL

  @override
  Future<RealtimeUpdatesData> build() async {
    // Initialize with default state
    final data = RealtimeUpdatesData();
    await _loadStoredEvents();
    return data;
  }

  Future<void> connect({String? userId}) async {
    try {
      // Close existing connection if any
      _channel?.sink.close();
      
      // Build WebSocket URL with user ID if provided
      String url = _websocketUrl;
      if (userId != null) {
        url += '?user_id=$userId';
      }
      
      // Connect to WebSocket
      _channel = IOWebSocketChannel.connect(url);
      
      // Listen for incoming messages
      _channel?.stream.listen(
        _onMessageReceived,
        onError: _handleError,
        onDone: _onConnectionClosed,
      );
      
      // Update connection status
      state = AsyncValue.data(state.value?.copyWith(isConnected: true) ?? 
          RealtimeUpdatesData(isConnected: true));
      
      // Load stored events from shared preferences
      await _loadStoredEvents();
    } catch (e) {
      // Handle connection error
      state = AsyncValue.data(state.value?.copyWith(isConnected: false) ?? 
          RealtimeUpdatesData(isConnected: false));
      _handleError(e);
    }
  }

  void _onMessageReceived(dynamic message) {
    try {
      // Parse the received message
      final Map<String, dynamic> data = jsonDecode(message);
      
      // Create a RealtimeEvent from the message
      final event = RealtimeEvent(
        type: RealtimeEventType.values.byName(data['type'] ?? 'systemNotification'),
        title: data['title'] ?? '',
        message: data['message'] ?? '',
        payload: data['payload'],
        timestamp: DateTime.now(),
      );
      
      // Add the event to the store
      _addEvent(event);
    } catch (e) {
      // If message parsing fails, log the error but continue
      // print('Error parsing WebSocket message: $e');
    }
  }

  void _onConnectionClosed() {
    // Connection closed unexpectedly
    state = AsyncValue.data(state.value?.copyWith(isConnected: false) ?? 
        RealtimeUpdatesData(isConnected: false));
    
    // Attempt to reconnect
    _scheduleReconnect();
  }

  void _handleError(dynamic error) {
    // Log error in production logging system
    state = AsyncValue.data(state.value?.copyWith(isConnected: false) ?? 
        RealtimeUpdatesData(isConnected: false));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      _reconnectTimer = Timer(_reconnectDelay, () {
        connect(userId: _getCurrentUserId());
      });
    }
  }

  String? _getCurrentUserId() {
    // In a real implementation, you would get the current user ID
    // from your auth provider or shared preferences
    // For now, we'll return a placeholder
    return null;
  }

  Future<void> _loadStoredEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getStringList('realtime_events') ?? [];
    
    final events = eventsJson
        .map((json) => RealtimeEvent.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
    
    final unreadCount = events.where((event) => !_isEventRead(event)).length;
    
    final currentState = state.value ?? RealtimeUpdatesData();
    state = AsyncValue.data(currentState.copyWith(
      events: events,
      unreadCount: unreadCount,
    ));
  }

  Future<void> _saveEvents(List<RealtimeEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = events
        .map((event) => jsonEncode(event.toJson()))
        .toList();
    await prefs.setStringList('realtime_events', eventsJson);
  }

  bool _isEventRead(RealtimeEvent event) {
    // In a real implementation, you would check against a list of read event IDs
    // For now, we'll use a simple approach with shared preferences
    return false;
  }

  Future<void> _addEvent(RealtimeEvent event) async {
    final currentState = state.value ?? RealtimeUpdatesData();
    final updatedEvents = [event, ...currentState.events];
    
    // Keep only last 100 events to prevent memory issues
    if (updatedEvents.length > 100) {
      updatedEvents.removeRange(100, updatedEvents.length);
    }
    
    await _saveEvents(updatedEvents);
    
    final unreadCount = updatedEvents.where((e) => !_isEventRead(e)).length;
    
    state = AsyncValue.data(currentState.copyWith(
      events: updatedEvents,
      unreadCount: unreadCount,
    ));
  }

  Future<void> markEventAsRead(RealtimeEvent event) async {
    // In a real implementation, you would mark the event as read
    // and update the unread count accordingly
    // For now, we'll just refresh the state
    await _loadStoredEvents();
  }

  Future<void> markAllAsRead() async {
    final currentState = state.value ?? RealtimeUpdatesData();
    state = AsyncValue.data(currentState.copyWith(unreadCount: 0));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    final currentState = state.value ?? RealtimeUpdatesData();
    state = AsyncValue.data(currentState.copyWith(isConnected: false));
  }

  // Send a message to the WebSocket
  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && state.value?.isConnected == true) {
      _channel?.sink.add(jsonEncode(message));
    }
  }

  // Simulate receiving a job notification
  Future<void> simulateJobNotification({
    required String title,
    required String message,
  }) async {
    final event = RealtimeEvent(
      type: RealtimeEventType.jobPosted,
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    await _addEvent(event);
  }

  // Simulate receiving an application notification
  Future<void> simulateApplicationNotification({
    required String title,
    required String message,
  }) async {
    final event = RealtimeEvent(
      type: RealtimeEventType.applicationReceived,
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    await _addEvent(event);
  }
}
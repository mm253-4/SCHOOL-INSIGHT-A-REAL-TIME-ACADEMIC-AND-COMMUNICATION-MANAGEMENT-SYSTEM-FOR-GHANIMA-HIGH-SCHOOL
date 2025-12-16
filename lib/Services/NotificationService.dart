import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel announcementsChannel =
      AndroidNotificationChannel(
    'announcements_channel',
    'Announcements',
    description: 'School announcements and updates',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel chatChannel =
      AndroidNotificationChannel(
    'chat_channel',
    'Chat',
    description: 'Messages from teachers and parents',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel assignmentsChannel =
      AndroidNotificationChannel(
    'assignments_channel',
    'Assignments',
    description: 'New assignments, reminders, and grades',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _local.initialize(initSettings,
        onDidReceiveNotificationResponse: _onSelectNotification);

    if (Platform.isAndroid) {
      final androidPlugin = _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(announcementsChannel);
        await androidPlugin.createNotificationChannel(chatChannel);
        await androidPlugin.createNotificationChannel(assignmentsChannel);
      }
    }
  }

  static Future<void> requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  static Future<void> showLocal({
    required String title,
    required String body,
    String? payload,
    String channelKey = 'announcements_channel',
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelKey,
      _channelName(channelKey),
      channelDescription: _channelDesc(channelKey),
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: const BigTextStyleInformation(''),
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    NotificationDetails details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _local.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title,
        body, details,
        payload: payload);
  }

  static String _channelName(String key) {
    switch (key) {
      case 'chat_channel':
        return 'Chat';
      case 'assignments_channel':
        return 'Assignments';
      default:
        return 'Announcements';
    }
  }

  static String _channelDesc(String key) {
    switch (key) {
      case 'chat_channel':
        return 'Messages from teachers and parents';
      case 'assignments_channel':
        return 'New assignments, reminders, and grades';
      default:
        return 'School announcements and updates';
    }
  }

  static void _onSelectNotification(NotificationResponse response) {
    // Handle deep link payloads here if needed (e.g., open specific chat)
    // Payload format suggestion: route|arg1|arg2
  }

  // Configure FCM foreground display
  static void bindFirebaseMessagingHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      final android = notification?.android;
      String channel = 'announcements_channel';
      if (android?.channelId != null) {
        channel = android!.channelId!;
      } else if (message.data['channel'] != null) {
        channel = message.data['channel']!;
      }
      if (notification != null) {
        await showLocal(
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
          payload: message.data['payload'],
          channelKey: channel,
        );
      }
    });
  }

  // Convenience: subscribe by role/topic
  static Future<void> subscribeToRoleTopic(String role) async {
    final topic = role.toLowerCase();
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }
}



import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  static Future<void> initialize() async {
    try {
      // Request permission for iOS
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'chat_messages', // channel ID
        'Chat Messages', // channel name
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle initial message when app is opened from terminated state
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

    } catch (e) {
      print('Failed to initialize notifications: $e');
    }
  }

  // Get FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  // Send message notification (for server-side use or testing)
  static Future<void> sendMessageNotification({
    required String token,
    required String senderName,
    required String messageContent,
    required String chatRoomId,
  }) async {
    try {
      // Note: In a real app, this would be done server-side
      // This is just for demonstration purposes
      
      final String serverKey = 'YOUR_SERVER_KEY_HERE'; // Replace with your server key
      
      const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';
      
      final Map<String, dynamic> notification = {
        'to': token,
        'priority': 'high',
        'notification': {
          'title': senderName,
          'body': messageContent,
          'sound': 'default',
          'badge': 1,
        },
        'data': {
          'type': 'chat_message',
          'chatRoomId': chatRoomId,
          'senderId': senderName,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(notification),
      );

      if (response.statusCode != 200) {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Show local notification
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'chat_messages',
            'Chat Messages',
            channelDescription: 'Notifications for new chat messages',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
            android: androidPlatformChannelSpecifics,
            iOS: iOSPlatformChannelSpecifics,
          );

      await _localNotifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  // Clear specific notification
  static Future<void> clearNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      print('Error clearing notification: $e');
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    try {
      print('Received foreground message: ${message.messageId}');
      
      // Show local notification when app is in foreground
      if (message.notification != null) {
        showLocalNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'New Message',
          body: message.notification!.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      print('Notification tapped: ${message.data}');
      
      // Navigate to appropriate screen based on notification data
      if (message.data['type'] == 'chat_message') {
        String? chatRoomId = message.data['chatRoomId'];
        if (chatRoomId != null) {
          // TODO: Navigate to chat screen
          // NavigationService.navigateToChatRoom(chatRoomId);
        }
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  // Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      print('Local notification tapped: ${response.payload}');
      
      if (response.payload != null) {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        
        if (data['type'] == 'chat_message') {
          String? chatRoomId = data['chatRoomId'];
          if (chatRoomId != null) {
            // TODO: Navigate to chat screen
            // NavigationService.navigateToChatRoom(chatRoomId);
          }
        }
      }
    } catch (e) {
      print('Error handling local notification tap: $e');
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      NotificationSettings settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Error checking notification settings: $e');
      return false;
    }
  }

  // Request notification permission
  static Future<bool> requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    print('Handling background message: ${message.messageId}');
    
    // Handle the background message
    // Note: You can't update UI or call methods that require BuildContext here
    
    // You could save the message to local storage to be processed when app opens
    // or perform other background tasks
    
  } catch (e) {
    print('Error in background message handler: $e');
  }
}

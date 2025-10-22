import 'api_client.dart';

class NotificationService {
  static Future<void> initialize() async {
    // Initialize notification service for Django backend
    // This can be extended to handle push notifications via Django
    print('Notification service initialized for Django backend');
  }
  
  static Future<void> markAsRead(int notificationId) async {
    try {
      final dio = await ApiClient().authed();
      await dio.patch('/api/notifications/$notificationId/read/');
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  
  static Future<void> markAllAsRead() async {
    try {
      final dio = await ApiClient().authed();
      await dio.post('/api/notifications/mark-all-read/');
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
}

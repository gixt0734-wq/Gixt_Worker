
import 'package:gixt_worker/services/Notification/Notification.dart';
import 'package:shared_preferences/shared_preferences.dart';


class NotificationCacheService {
  static const String _key = 'notification_cache';

  Future<List<NotificationModel>> loadNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data == null || data.isEmpty) return [];
      return NotificationModel.decodeList(data);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotification(List<NotificationModel> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, NotificationModel.encodeList(messages));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
import 'dart:convert';

class NotificationModel {
  final int? id;
  final String? text;
  final String type;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] as int?,            // 👈 nullable
        text: json['text'] as String? ?? '',
        type: json['type'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );

  static String encodeList(List<NotificationModel> messages) =>
      jsonEncode(messages.map((m) => m.toJson()).toList());

  static List<NotificationModel> decodeList(String source) =>
      (jsonDecode(source) as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
}
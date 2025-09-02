class NotificationModel {
  String title;
  String body;

  NotificationModel({required this.title, required this.body});

  static NotificationModel empty() => NotificationModel(title: '', body: '');

  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'Body': body,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['Title'] ?? '',
      body: json['Body'] ?? '',
    );
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:monqez_app/Backend/NotificationRoutes/NotificationRoute.dart';

class AdminUserNotification extends NotificationRoute {
  AdminUserNotification(RemoteMessage message, bool isBackground) : super(message, isBackground);
  @override
  Future onSelectNotification(String payload) async {
    throw UnimplementedError();
  }
}
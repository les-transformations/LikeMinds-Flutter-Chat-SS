import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';
import 'package:likeminds_chat_ss_fl/src/navigation/router.dart';
import 'package:likeminds_chat_ss_fl/src/service/navigation_service.dart';
import 'package:likeminds_chat_ss_fl/src/utils/imports.dart';
import 'package:likeminds_chat_ss_fl/src/views/chatroom_page.dart';
import 'package:likeminds_chat_ss_fl/src/views/home_page.dart';
import 'package:overlay_support/overlay_support.dart';

/// This class handles all the notification related logic
/// It registers the device for notifications in the SDK
/// It handles the notification when it is received and shows it
/// It routes the notification to the appropriate screen
/// Since this is a singleton class, it is initialized on the client side
class LMNotificationHandler {
  late final String deviceId;
  late final String fcmToken;
  int? memberId;

  static LMNotificationHandler? _instance;
  static LMNotificationHandler get instance =>
      _instance ??= LMNotificationHandler._();

  LMNotificationHandler._();

  /// Initialize the notification handler
  /// This is called from the client side
  /// It initializes the [fcmToken] and the [deviceId]
  void init({
    required String deviceId,
    required String fcmToken,
  }) {
    this.deviceId = deviceId;
    this.fcmToken = fcmToken;
  }

  /// Register the device for notifications
  /// This is called from the client side
  /// It calls the [registerDevice] method of the [LikeMindsService]
  /// It initializes the [memberId] which is used to route the notification
  /// If the registration is successful, it prints success message
  void registerDevice(int memberId) async {
    if (fcmToken != null) {
      RegisterDeviceRequest request = RegisterDeviceRequest(
        token: fcmToken,
        memberId: memberId,
        deviceId: deviceId,
      );
      this.memberId = memberId;
      final response =
          await locator<LikeMindsService>().registerDevice(request);
      if (response.success) {
        debugPrint("Device registered for notifications successfully");
      } else {
        throw Exception("Device registration for notification failed");
      }
    } else {
      debugPrint(
          "Notifications not registered, will not show new notifications.");
    }
  }

  /// Handle the notification when it is received
  /// This is called from the client side when notification [message] is received
  /// and is needed to be handled, i.e. shown and routed to the appropriate screen
  Future<void> handleNotification(RemoteMessage message, bool show) async {
    debugPrint("--- Notification received in LEVEL 2 ---");
    if (message.data["category"].contains("Chat")) {
      message.toMap().forEach((key, value) {
        debugPrint("$key: $value");
        if (key == "data") {
          message.data.forEach((key, value) {
            debugPrint("$key: $value");
          });
        }
      });
      GlobalKey<NavigatorState> rootNavigatorKey =
          locator<NavigationService>().navigatorKey;
      // First, check if the message contains a data payload.
      if (show && message.data.isNotEmpty) {
        //Add LM check for showing LM notifications
        showNotification(message, rootNavigatorKey);
      } else if (message.data.isNotEmpty) {
        // Second, extract the notification data and routes to the appropriate screen
        routeNotification(message, rootNavigatorKey);
      }
    }
  }

  void routeNotification(
    RemoteMessage message,
    GlobalKey<NavigatorState> rootNavigatorKey,
  ) async {
    Map<String, String> queryParams = {};
    String host = "";

    // Only notifications with data payload are handled
    if (message.data.isNotEmpty) {
      final Map<String, dynamic> notifData = message.data;
      final String category = notifData["category"];
      final String route = notifData["route"]!;

      // If the notification is a feed notification, extract the route params
      if (category.toString().toLowerCase() == "chat room") {
        final Uri routeUri = Uri.parse(route);
        final Map<String, String> routeParams =
            routeUri.hasQuery ? routeUri.queryParameters : {};
        final String routeHost = routeUri.host;
        host = routeHost;
        debugPrint("The route host is $routeHost");
        queryParams.addAll(routeParams);
        queryParams.forEach((key, value) {
          debugPrint("$key: $value");
        });
      }
    }

    if (host == "collabcard") {
      rootNavigatorKey.currentState!
          .push(MaterialPageRoute(builder: (context) => const HomePage()));

      // router.push(path);

      rootNavigatorKey.currentState!.push(MaterialPageRoute(
          builder: (context) => ChatRoomPage(
              chatroomId: int.parse(queryParams["collabcard_id"]!))));
    }
  }

  /// Show a simple notification using overlay package
  /// This is a dismissable notification shown on the top of the screen
  /// It is shown when the notification is received in foreground
  void showNotification(
    RemoteMessage message,
    GlobalKey<NavigatorState> rootNavigatorKey,
  ) {
    if (message.data.isNotEmpty) {
      showSimpleNotification(
        GestureDetector(
          onTap: () {
            routeNotification(
              message,
              rootNavigatorKey,
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LMTextView(
                text: message.data["title"],
                textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kDarkGreyColor),
              ),
              const SizedBox(height: 4),
              LMTextView(
                text: message.data["sub_title"],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textStyle: const TextStyle(
                  fontSize: 10,
                  color: kGrey3Color,
                ),
              ),
            ],
          ),
        ),
        background: Colors.white,
        duration: const Duration(seconds: 3),
        leading: const LMIcon(
          type: LMIconType.icon,
          icon: Icons.notifications,
          color: secondary,
          size: 28,
        ),
        trailing: LMIcon(
          type: LMIconType.icon,
          icon: Icons.swipe_right_outlined,
          color: Colors.grey.shade400,
          size: 18,
        ),
        position: NotificationPosition.top,
        slideDismissDirection: DismissDirection.horizontal,
      );
    }
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:sales/Auth/Signin.dart';
// import 'package:sales/Complaint/complaint.dart';
// import 'package:sales/FollowUp/followup.dart';
// import 'package:sales/Lead/lead_list.dart';
// import 'package:sales/Lead/leadmanagement.dart';
// import 'package:sales/Order/order_managmenet.dart';
// import 'package:sales/Profile/profile.dart';
// import 'package:sales/Review/review.dart';
// import 'package:sales/firebase_options.dart';
// import 'package:sales/Home/home.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Divya Crafts',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         fontFamily: 'Inter',
//         scaffoldBackgroundColor: const Color(0xFFF8FAFC),
//       ),
//       initialRoute: '/',
//       getPages: [
//         GetPage(name: '/', page: () => const AuthWrapper()),
//         GetPage(name: "/leadmanagment", page: () => LeadManagement()),
//         GetPage(name: "/followup", page: () => const FollowupPage()),
//         GetPage(name: "/ordermanagement", page: () => OrderManagement()),
//         GetPage(name: "/review", page: () => Review()),
//         GetPage(name: "/complaint", page: () => Complaint()),
//         GetPage(name: "/profile", page: () => Profile()),
//         GetPage(name: "/login", page: () => Signin()),
//         GetPage(name: '/leadlist', page: () => LeadList()),

//       ],
//     );
//   }
// }

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     User? user = FirebaseAuth.instance.currentUser;

//     if (user != null) {
//       return Home(); // user is logged in
//     } else {
//       return Signin(); // user is not logged in
//     }
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:sales/Auth/Signin.dart';
import 'package:sales/Complaint/complaint.dart';
import 'package:sales/FollowUp/followup.dart';
import 'package:sales/Lead/lead_list.dart';
import 'package:sales/Lead/leadmanagement.dart';
import 'package:sales/Order/order_managmenet.dart';
import 'package:sales/Profile/profile.dart';
import 'package:sales/Review/review.dart';
import 'package:sales/firebase_options.dart';
import 'package:sales/Home/home.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   runApp(MyApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔧 Setup local notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // 🔧 Initialize notification plugin
  const InitializationSettings initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 🔁 Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  // 🔁 Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'default_channel',
  'Default Notifications',
  importance: Importance.high,
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.notification?.title}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Divya Crafts',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const AuthWrapper()),
        GetPage(name: "/leadmanagment", page: () => LeadManagement()),
        GetPage(name: "/followup", page: () => const FollowupPage()),
        GetPage(name: "/ordermanagement", page: () => OrderManagement()),
        GetPage(name: "/review", page: () => Review()),
        GetPage(name: "/complaint", page: () => Complaint()),
        GetPage(name: "/profile", page: () => Profile()),
        GetPage(name: "/login", page: () => Signin()),
        GetPage(name: '/leadlist', page: () => LeadList()),
      ],
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return Home(); // user is logged in
    } else {
      return Signin(); // user is not logged in
    }
  }
}

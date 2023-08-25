
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:savenoty/page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  await AndroidAlarmManager.initialize();
  await AndroidAlarmManager.oneShot(
      const Duration(seconds: 30), cants, initializeService,
      exact: true);

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Notify(),
    );
  }
}


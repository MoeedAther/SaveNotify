import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_listener_service/notification_event.dart';

import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:savenoty/api/api.dart';
import 'package:savenoty/aws.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

StreamSubscription<ServiceNotificationEvent>? _subscription;
List<ServiceNotificationEvent> events = [];
bool isPermiso = false;
List dato = [];
int cantNoty = 0;
String name = '';
String price = '';
String fecha = '';
String celular = '';
String user = '';
String password = '';
String? deviceId;
bool cargando = true;
List Lname = [];
List Lprice = [];
int cants = 0;
String elContent = '';
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final prefs = await SharedPreferences.getInstance();

  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setString("hello", "world");

  /// OPTIONAL when use custom notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
        /// the notification id must be equals with AndroidConfiguration when you call configure() method.
        flutterLocalNotificationsPlugin.show(
          888,
          'Notificaciones',
          'Capturando notificaciones en segundo plano',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );

        // if you don't using custom notification, uncomment this
        // service.setForegroundNotificationInfo(
        //   title: "My App Service",
        //   content: "Updated at ${DateTime.now()}",
        // );
      }
    }

    /// you can see this log in logcat
    print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');
    celular = prefs.getString('numero') ?? '';
    user = prefs.getString('user') ?? '';
    password = prefs.getString('password') ?? '';
    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }
    _subscription?.cancel();
    initSuscription();

    // prefs.setInt('num', num);
    // test using external plugin

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

initSuscription() async {
  final prefs = await SharedPreferences.getInstance();

  /// you can see this log in logcat
  print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');
  celular = prefs.getString('numero') ?? '';
  user = prefs.getString('user') ?? '';
  password = prefs.getString('password') ?? '';
  final deviceInfo = DeviceInfoPlugin();
  String? device;
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    device = androidInfo.model;
  }

  if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    device = iosInfo.model;
  }

  _subscription =
      NotificationListenerService.notificationsStream.listen((event) async {
    if (celular != '' &&
        user != '' &&
        password != '' &&
        event.content != null &&
        event.packageName == 'com.bcp.innovacxion.yapeapp' &&
        //'com.armor.pass' &&
        event.hasRemoved == false &&
        dato.isEmpty) {
      dato.add(event);
      for (var i = 0; i < event.content!.length; i++) {
        if (i >= 6) {
          Lname.add(event.content![i]);
          if (event.content![i] == ' ' && event.content![i + 1] == 't') {
            Lname.removeAt(Lname.length - 1);
            name = Lname.join();
            break;
          }
        }
      }
      for (var i = event.content!.length - 1; i > 0; i--) {
        Lprice.add(event.content![i]);
        if (event.content![i] == ' ' &&
            event.content![i - 1] == '/' &&
            event.content![i - 2] == 'S') {
          Lprice.removeAt(Lprice.length - 1);
          price = Lprice.reversed.join();
          break;
        }
      }
      fecha = DateFormat('yyyy-MM-dd kk:mm').format(DateTime.now());
      cantNoty++;
      events.add(event);
      prefs.setInt('value', cantNoty);
      Lname.clear();
      Lprice.clear();
      print('antes del singin');
      Aws().singin(user, password).then((value) {
        Api().sendNoty(value!, celular, fecha, price, name, device!);
      });
      /* cants++;
        if (cants == 1 ) {
          print('La cant -> $cants');
          print('El content -> $elContent');
          elContent = event.content!;
          for (var i = 0; i < event.content!.length; i++) {
            if (i >= 6) {
              Lname.add(event.content![i]);
              if (event.content![i] == ' ' && event.content![i + 1] == 't') {
                Lname.removeAt(Lname.length - 1);
                name = Lname.join();
                break;
              }
            }
          }
          for (var i = event.content!.length - 1; i > 0; i--) {
            Lprice.add(event.content![i]);
            if (event.content![i] == ' ' &&
                event.content![i - 1] == '/' &&
                event.content![i - 2] == 'S') {
              Lprice.removeAt(Lprice.length - 1);
              price = Lprice.reversed.join();
              break;
            }
          }
          fecha = DateFormat('yyyy-MM-dd kk:mm').format(DateTime.now());
          cantNoty++;
          events.add(event);
          prefs.setInt('value', cantNoty);
          Lname.clear();
          Lprice.clear();
          Aws().singin(user, password).then((value) {
            print('el value -> $value');
            print('el celular -> $celular');
            print('el fecha -> $fecha');
            print('el price -> $price');
            print('el name -> $name');
            print('el deviceId -> $device');
            Api().sendNoty(value!, celular, fecha, price, name, device!);
          });
        } else if (cants == 2 && elContent == event.content) {
          cants = 0;
        } else if (cants == 2 && elContent != event.content) {
          for (var i = 0; i < event.content!.length; i++) {
            if (i >= 6) {
              Lname.add(event.content![i]);
              if (event.content![i] == ' ' && event.content![i + 1] == 't') {
                Lname.removeAt(Lname.length - 1);
                name = Lname.join();
                break;
              }
            }
          }
          for (var i = event.content!.length - 1; i > 0; i--) {
            Lprice.add(event.content![i]);
            if (event.content![i] == ' ' &&
                event.content![i - 1] == '/' &&
                event.content![i - 2] == 'S') {
              Lprice.removeAt(Lprice.length - 1);
              price = Lprice.reversed.join();
              break;
            }
          }
          fecha = DateFormat('yyyy-MM-dd kk:mm').format(DateTime.now());
          cantNoty++;
          events.add(event);
          prefs.setInt('value', cantNoty);
          Lname.clear();
          Lprice.clear();
          Aws().singin(user, password).then((value) {
            Api().sendNoty(value!, celular, fecha, price, name, device!);
          });
          cants = 0;
        } */
    } else if (dato.isNotEmpty) {
      dato = [];
    }
  });
}

class Notify extends StatefulWidget {
  const Notify({Key? key}) : super(key: key);

  @override
  State<Notify> createState() => _MyAppState();
}

class _MyAppState extends State<Notify> {
  TextEditingController controller = TextEditingController();
  TextEditingController controllerUser = TextEditingController();
  TextEditingController controllerPass = TextEditingController();

  @override
  void initState() {
    canStart();

    super.initState();
  }

  canStart() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      celular = prefs.getString('numero') ?? '';
      user = prefs.getString('user') ?? '';
      password = prefs.getString('password') ?? '';
    });
    if (celular != '' && user != '' && password != '') {
      print('1111111111111111');
      initAutoStart();
      getPhone();
    } else {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> initAutoStart() async {
    try {
      //check auto-start availability.
      var test = await (isAutoStartAvailable as Future<bool?>);
      print('Lo de autostart => $test');
      //if available then navigate to auto-start setting page.
      print('22222222');
      if (!test!) await getAutoStartPermission();
    } catch (e) {
      print(e);
    }
    if (!mounted) return;
  }

  void getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      celular = prefs.getString('numero') ?? '';
      user = prefs.getString('user') ?? '';
      password = prefs.getString('password') ?? '';
    });
    if (celular != '' && user != '' && password != '') {
      print('entra gets');
      print('33333333');
      setState(() {
        _getId();
        getPermiso();
        bgMode();
        cargando = false;
      });
    } else {
      setState(() {
        cargando = false;
      });
    }
  }

  void _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      deviceId = iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      print('44444444');
      setState(() {
        deviceId = androidDeviceInfo.model; // unique ID on Android
      });
    }
  }

  final androidConfig = const FlutterBackgroundAndroidConfig(
      notificationTitle: "flutter_background example app",
      notificationText:
          "Background notification for keeping the example app running in the background",
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon:
          AndroidResource(name: 'background_icon', defType: 'drawable'));
  bgMode() async {
    await FlutterBackground.initialize(androidConfig: androidConfig);
    bool hasPermissions = await FlutterBackground.hasPermissions;
    print('tinene permisos -> $hasPermissions');
    bool success = await FlutterBackground.enableBackgroundExecution();
    print('el success => $success');
  }

  bool isLogin = false;
  // List Lname = [];
  // List Lprice = [];
  // int cants = 0;
  // String elContent = '';
  List data = [];
  getPermiso() async {
    final prefs = await SharedPreferences.getInstance();
    final res = await NotificationListenerService.isPermissionGranted();
    cantNoty = prefs.getInt('value') ?? 0;
    if (!res) {
      final res1 = await NotificationListenerService.requestPermission();
      if (res1) {
        setState(() {
          isPermiso = true;
        });
      }
    }
    if (_subscription?.isPaused == null && res) {
      print('se ejecuta en el suscription pause');
      setState(() {
        if (isLogin) {
          _subscription = NotificationListenerService.notificationsStream
              .listen((event) async {
            if (celular != '' &&
                user != '' &&
                password != '' &&
                event.content != null &&
                event.packageName == 'com.bcp.innovacxion.yapeapp' &&
                //'com.armor.pass' &&
                event.hasRemoved == false &&
                dato.isEmpty) {
              print('555555555');
              setState(() {
                events.add(event);
                dato.add(event);
              });
              for (var i = 0; i < event.content!.length; i++) {
                if (i >= 6) {
                  Lname.add(event.content![i]);
                  if (event.content![i] == ' ' &&
                      event.content![i + 1] == 't') {
                    Lname.removeAt(Lname.length - 1);
                    name = Lname.join();
                    print('777777777');
                    break;
                  }
                }
              }
              for (var i = event.content!.length - 1; i > 0; i--) {
                Lprice.add(event.content![i]);
                if (event.content![i] == ' ' &&
                    event.content![i - 1] == '/' &&
                    event.content![i - 2] == 'S') {
                  Lprice.removeAt(Lprice.length - 1);
                  price = Lprice.reversed.join();
                  print('999999999999');
                  break;
                }
              }
              print('55555555555');
              fecha = DateFormat('yyyy-MM-dd kk:mm').format(DateTime.now());
              cantNoty++;
              events.add(event);
              prefs.setInt('value', cantNoty);
              Lname.clear();
              Lprice.clear();
              Aws().singin(user, password).then((value) {
                Api().sendNoty(value!, celular, fecha, price, name, deviceId!);
              });
            } else if (dato.isNotEmpty) {
              dato = [];
            }
          });
        } else {
          _subscription = NotificationListenerService.notificationsStream
              .listen((event) async {
            if (event.content != null &&
                event.packageName == 'com.bcp.innovacxion.yapeapp' &&
                //'com.armor.pass' &&
                event.hasRemoved == false &&
                data.isEmpty) {
              setState(() {
                events.add(event);
                data.add(event);
              });
              print('888888888888888');
            } else if (data.isNotEmpty) {
              setState(() {
                data = [];
              });
              print('33333333333');
            }
          });
        }
        isPermiso = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Notifications'),
        actions: [
          IconButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.clear();
                setState(() {
                  celular == '';
                  user == '';
                  password == '';
                });
              },
              icon: Icon(Icons.remove))
        ],
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: celular == '' || user == '' || password == ''
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                                hintText: 'Número celular'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: TextField(
                            controller: controllerUser,
                            decoration:
                                const InputDecoration(hintText: 'Usuario'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: TextField(
                            controller: controllerPass,
                            decoration:
                                const InputDecoration(hintText: 'Contraseña'),
                          ),
                        ),
                        ElevatedButton(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final result = await NotificationListenerService
                                  .isPermissionGranted();
                              if (!result) {
                                final res = await NotificationListenerService
                                    .requestPermission();
                                if (res) {
                                  setState(() {
                                    isPermiso = true;
                                  });
                                }
                              } else if (controller.text != '' &&
                                  controllerUser.text != '' &&
                                  controllerPass.text != '') {
                                await prefs.setString(
                                    'numero', controller.text);
                                await prefs.setString(
                                    'user', controllerUser.text);
                                await prefs.setString(
                                    'password', controllerPass.text);
                                setState(() {
                                  celular = controller.text;
                                  user = controllerUser.text;
                                  password = controllerPass.text;
                                  isPermiso = true;
                                  isLogin = true;
                                });
                                await initializeService();
                                initAutoStart();
                                getPhone();
                              }
                            },
                            child: const Text('Guardar'))
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            isPermiso
                                ? const SizedBox()
                                : TextButton(
                                    onPressed: () async {
                                      final res =
                                          await NotificationListenerService
                                              .requestPermission();
                                      if (res) {
                                        setState(() {
                                          isPermiso = true;
                                        });
                                      }
                                    },
                                    child: const Text("Aceptar Permiso"),
                                  ),
                            const SizedBox(height: 20.0),
                            !isPermiso
                                ? const SizedBox()
                                : _subscription?.isPaused == false
                                    ? const SizedBox()
                                    : TextButton(
                                        onPressed: () {
                                          _subscription =
                                              NotificationListenerService
                                                  .notificationsStream
                                                  .listen((event) async {
                                            final prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            if (event.content != null &&
                                                event.packageName ==
                                                    'com.bcp.innovacxion.yapeapp' &&
                                                //'com.armor.pass' &&
                                                event.hasRemoved == false) {
                                              cants++;
                                              if (cants == 1) {
                                                elContent = event.content!;
                                                for (var i = 0;
                                                    i < event.content!.length;
                                                    i++) {
                                                  if (i >= 6) {
                                                    Lname.add(
                                                        event.content![i]);
                                                    if (event.content![i] ==
                                                            ' ' &&
                                                        event.content![i + 1] ==
                                                            't') {
                                                      Lname.removeAt(
                                                          Lname.length - 1);
                                                      name = Lname.join();
                                                      break;
                                                    }
                                                  }
                                                }
                                                for (var i =
                                                        event.content!.length -
                                                            1;
                                                    i > 0;
                                                    i--) {
                                                  Lprice.add(event.content![i]);
                                                  if (event.content![i] ==
                                                          ' ' &&
                                                      event.content![i - 1] ==
                                                          '/' &&
                                                      event.content![i - 2] ==
                                                          'S') {
                                                    Lprice.removeAt(
                                                        Lprice.length - 1);
                                                    price =
                                                        Lprice.reversed.join();
                                                    break;
                                                  }
                                                }
                                                setState(() {
                                                  fecha = DateFormat(
                                                          'yyyy-MM-dd kk:mm')
                                                      .format(DateTime.now());
                                                  cantNoty++;
                                                  events.add(event);
                                                  prefs.setInt(
                                                      'value', cantNoty);
                                                  Lname.clear();
                                                  Lprice.clear();
                                                  Aws()
                                                      .singin(user, password)
                                                      .then((value) {
                                                    Api().sendNoty(
                                                        value!,
                                                        celular,
                                                        fecha,
                                                        price,
                                                        name,
                                                        deviceId!);
                                                  });
                                                });
                                              } else if (cants == 2 &&
                                                  elContent == event.content) {
                                                cants = 0;
                                              } else if (cants == 2 &&
                                                  elContent != event.content) {
                                                for (var i = 0;
                                                    i < event.content!.length;
                                                    i++) {
                                                  if (i >= 6) {
                                                    Lname.add(
                                                        event.content![i]);
                                                    if (event.content![i] ==
                                                            ' ' &&
                                                        event.content![i + 1] ==
                                                            't') {
                                                      Lname.removeAt(
                                                          Lname.length - 1);
                                                      name = Lname.join();
                                                      break;
                                                    }
                                                  }
                                                }
                                                for (var i =
                                                        event.content!.length -
                                                            1;
                                                    i > 0;
                                                    i--) {
                                                  Lprice.add(event.content![i]);
                                                  if (event.content![i] ==
                                                          ' ' &&
                                                      event.content![i - 1] ==
                                                          '/' &&
                                                      event.content![i - 2] ==
                                                          'S') {
                                                    Lprice.removeAt(
                                                        Lprice.length - 1);
                                                    price =
                                                        Lprice.reversed.join();
                                                    break;
                                                  }
                                                }
                                                setState(() {
                                                  fecha = DateFormat(
                                                          'yyyy-MM-dd kk:mm')
                                                      .format(DateTime.now());
                                                  cantNoty++;
                                                  events.add(event);
                                                  prefs.setInt(
                                                      'value', cantNoty);
                                                  Lname.clear();
                                                  Lprice.clear();
                                                  Aws()
                                                      .singin(user, password)
                                                      .then((value) {
                                                    Api().sendNoty(
                                                        value!,
                                                        celular,
                                                        fecha,
                                                        price,
                                                        name,
                                                        deviceId!);
                                                  });
                                                });
                                                cants = 0;
                                              }
                                            }
                                          });
                                          setState(() {});
                                        },
                                        child: const Text("Empezar"),
                                      ),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: events.length,
                            itemBuilder: (_, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ListTile(
                                  onTap: () async {
                                    try {
                                      await events[index].sendReply(
                                          "This is an auto response");
                                    } catch (e) {
                                      log(e.toString());
                                    }
                                  },
                                  trailing: events[index].hasRemoved!
                                      ? const Text(
                                          "Removed",
                                          style: TextStyle(color: Colors.red),
                                        )
                                      : const SizedBox.shrink(),
                                  title:
                                      Text(events[index].title ?? "No title"),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        events[index].content ?? "no content",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8.0),
                                      events[index].canReply!
                                          ? const Text(
                                              "Replied with: This is an auto reply",
                                              style: TextStyle(
                                                  color: Colors.purple),
                                            )
                                          : const SizedBox.shrink(),

                                      // events[index].haveExtraPicture
                                      //     ? Image.memory(
                                      //         events[index].extrasPicture!,
                                      //       )
                                      //     : const SizedBox.shrink(),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
            ),
    );
  }
}

import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hear_for_you/modules/regular_module.dart';
import 'package:hear_for_you/modules/voice_module.dart';

import 'package:hear_for_you/screens/regular_screen.dart';
import 'package:hear_for_you/screens/setting_screen.dart';
import 'package:hear_for_you/screens/spalsh_screen.dart';
import 'package:hear_for_you/screens/voice_screen.dart';

import 'package:hear_for_you/service/full_screen_alert/provider/alarm_provider.dart';
import 'package:hear_for_you/service/full_screen_alert/provider/alarm_state.dart';
import 'package:hear_for_you/service/full_screen_alert/service/alarm_polling_worker.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidAlarmManager.initialize();
  }

  final AlarmState alarmState = AlarmState();
  AlarmPollingWorker().createPollingWorker(alarmState);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => alarmState),
      ChangeNotifierProvider(create: (context) => AlarmProvider()),
      ChangeNotifierProvider(create: (context) => RecordModule()),
      ChangeNotifierProvider(create: (context) => VoiceModule()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: darkMode ? kBlack : kGrey1,
      systemNavigationBarIconBrightness:
          darkMode ? Brightness.light : Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: darkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: darkMode ? Brightness.dark : Brightness.light,
    ));

    Map<int, Color> color = {
      50: const Color.fromRGBO(255, 255, 255, .1),
      100: const Color.fromRGBO(255, 255, 255, .2),
      200: const Color.fromRGBO(255, 255, 255, .3),
      300: const Color.fromRGBO(255, 255, 255, .4),
      400: const Color.fromRGBO(255, 255, 255, .5),
      500: const Color.fromRGBO(255, 255, 255, .6),
      600: const Color.fromRGBO(255, 255, 255, .7),
      700: const Color.fromRGBO(255, 255, 255, .8),
      800: const Color.fromRGBO(255, 255, 255, .9),
      900: const Color.fromRGBO(255, 255, 255, 1),
    };

    MaterialColor colorCustom = MaterialColor(0xFFFFFFFF, color);

    return MaterialApp(
      title: 'Hear For You',
      // 기기의 폰트 크기 무시
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
          child: child!,
        );
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: colorCustom,
        fontFamily: 'PretendardMedium',
        textSelectionTheme: TextSelectionThemeData(
            cursorColor: kGrey4,
            selectionHandleColor: kGrey4,
            selectionColor: kGrey4.withOpacity(0.3)),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      ),
      // home: name == "" ? const LoginScreen() : const BottomNavBar(),
      // home: const BottomNavBar(),
      home: const SplashScreen(),
    );
  }
}

class BottomNavBar extends StatefulWidget {
  int selectedIndex;
  BottomNavBar({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int selectedIndex = 1;
  final screens = [
    const VoiceScreen(),
    const RegularScreen(),
    const SettingScreen()
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
    setState(() {});

    ToastContext().init(context);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: darkMode ? kBlack : kGrey1,
      systemNavigationBarIconBrightness:
          darkMode ? Brightness.light : Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: darkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: darkMode ? Brightness.dark : Brightness.light,
    ));

    context.read<RecordModule>().setContext(context);

    Widget bottomNavBar() {
      return BottomNavigationBar(
        backgroundColor: darkMode ? kBlack : kGrey1,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        selectedItemColor: kMain,
        unselectedItemColor: darkMode ? kWhite : kGrey8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.keyboard_voice_rounded,
              size: 26,
              color: selectedIndex == 0
                  ? kMain
                  : darkMode
                      ? kWhite
                      : kGrey8,
            ),
            label: '음성모드',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_filled,
              size: 26,
              color: selectedIndex == 1
                  ? kMain
                  : darkMode
                      ? kWhite
                      : kGrey8,
            ),
            label: '상시모드',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings_rounded,
              size: 26,
              color: selectedIndex == 2
                  ? kMain
                  : darkMode
                      ? kWhite
                      : kGrey8,
            ),
            label: '설정',
          ),
        ],
        onTap: (int index) {
          setState(() {
            selectedIndex = index;
            if (selectedIndex != 0) {
              context.read<VoiceModule>().stopListening();
              if (regularValue && !context.read<RecordModule>().isRecording) {
                ToastContext().init(context);

                Toast.show('5초 뒤 상시모드가 시작됩니다.',
                    duration: Toast.lengthLong, gravity: Toast.bottom);
                debugPrint('debugging : 상시모드 재접근 rV $regularValue');

                context.read<RecordModule>().record();
              }
            }
            if (selectedIndex == 0) {
              debugPrint('debugging : 음성모드 접근 rV $regularValue');
              if (regularValue) {
                ToastContext().init(context);
                Toast.show(
                  '상시모드가 잠시 중단됩니다.',
                  duration: Toast.lengthLong,
                  gravity: Toast.bottom,
                );
                context.read<RecordModule>().stop();
              }
            }
          });
        },
      );
    }

    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            body: ColorfulSafeArea(
          color: darkMode ? kBlack : kGrey1,
          bottom: true,
          child: Stack(
            children: [
              screens[selectedIndex],
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child:
                    keyboardHeight == 0 ? bottomNavBar() : Container(height: 0),
              ),
            ],
          ),
        )));
  }
}

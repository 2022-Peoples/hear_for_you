import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'flash_light.dart';

final notifications = FlutterLocalNotificationsPlugin();

//1. 앱 로드시 initNotification을 등록해줘야 합니다!
initNotification() async {
  //안드로이드용 아이콘파일 이름
  var androidSetting = const AndroidInitializationSettings('app_icon');

  //ios에서 앱 로드시 유저에게 권한요청하려면
  var iosSetting = const DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  var initializationSettings =
      InitializationSettings(android: androidSetting, iOS: iosSetting);
  await notifications.initialize(
    initializationSettings,
    //알림 누를때 함수실행하고 싶으면
    //onSelectNotification: 함수명추가
  );
}

//2. 이 함수를 필요한 곳에서 실행하면 알림이 나옴. content에는 원하는 알림 내용 넣기!
showNotification(var alarmID, var content) async {
  if (Platform.isAndroid) {
    FlashLight.startFlashLight(0);
  }
  var androidDetails = const AndroidNotificationDetails(
    '유니크한 알림 채널 ID',
    '알림종류 설명',
    priority: Priority.high,
    importance: Importance.max,
    color: Color.fromARGB(255, 255, 0, 0),
  );

  var iosDetails = const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  // 알림 id, 제목, 내용 맘대로 채우기
  notifications.show(1, '$alarmID', '$content',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: '부가정보' // 부가정보
      );
}

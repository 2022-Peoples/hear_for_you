import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';
import '../constants.dart';
import '../modules/regular_module.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/missed_alert.dart';
import '../widgets/regular_popup.dart';
import 'package:wav/wav.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart' as setting;
import 'full_screen_alert/provider/alarm_provider.dart';
import 'full_screen_alert/service/alarm_scheduler.dart';
import 'full_screen_alert/view/alarm_screen.dart';
import 'notification.dart' as notification;

class FunctionClass {
  /* 
    @@@@@@@@@@@ 현재 FunctionClass 내부에 존재하는 함수에 대한 간단한 정보들 @@@@@@@@@@@

    ### 모든 함수는 static 함수임! 별도의 객체 생성 없이 사용 가능

    ## 외부에서 호출하여 사용해야 하는 함수들
    void showPopup(BuildContext context)  : 실행하면 저장된 음원을 자르고 서버로 보내서 결과를 받아온다. 함수 실행과 동시에 팝업창을 띄우며,
                                            분석된 결과는 팝업창에 보여지고 알람이 발생한다(알람 방식은 134번째 줄에서 수정!). 
                                            일정 데시벨 이상의 소리가 감지된 경우에 이 함수 하나만 실행해주면 됨.

    bool raiseDecibelCheck()              : 저장된 로그들을 확인하고, 데시벨 기준을 높여야 할 상황인지 알려준다. 
                                            True면 높여야 하는 것, False면 높이지 않아도 되는 것. 
                                            showPopup 실행 이후에 바로 같이 사용되면 좋을 것 같음.

    List<String> getLogString()           : 저장되어있는 로그들을 알림창 등에 사용 가능한 형태로 반환해준다. 로그를 출력하려 할 때 사용한다. 
                                            분석에 실패한 값(결과가 unknown인 값)은 리스트에 나오지 않음.
                                            Example --------------------------------------------------------
                                            ["사이렌 소리가 17시 30분 24초에 발생하였습니다.",
                                            "차량 급정거 소리가 18시 31분 02초에 발생하였습니다.",
                                            ...
                                            ]
                                            ----------------------------------------------------------------

    ## 내부에서만 사용되는(외부에서 호출될 필요 없는) 함수들
    Future<String> cutFile() async
    Future<String> uploadFile() async 
    Future<String> getPreciction() async
    Future<String> getPath({fileName = "audio.wav"})
    int getMinuteValue(DateTime time)
  
  */

  static bool dB_raised = false;
  // 서버 주소! 달라지면 여기서 바꾸면 됨
  static const address = "http://hearforyou.site";
  // static const address = "http://127.0.0.1";

  // 이 함수를 부르면 파일 자르기, 서버로 데이터 전송, 데이터 받아서 반환 등의 과정을 자동으로 처리하고 알람을 띄워줌
  static int logsToShown() {
    List<num> numList;
    for (int i = setting.logList.length - 1; i >= 0; i--) {
      if (setting.logList[i].split(",")[0] != "unknown" &&
          setting.logList[i].split(",")[0] != "null" &&
          setting.logList[i].split(",")[2] == "false") {
        return i;
      }
    }
    return -1;
  }

  static int howManyLogsLeft() {
    int returnValue = 0;
    for (int i = setting.logList.length - 1; i >= 0; i--) {
      if (setting.logList[i].split(",")[0] != "unknown" &&
          setting.logList[i].split(",")[0] != "null" &&
          setting.logList[i].split(",")[2] == "false") {
        returnValue += 1;
      }
    }
    return returnValue;
  }

  static void changeLogState(int index) async {
    var pref = await SharedPreferences.getInstance();
    var oldLogState = setting.logList[index].split(",");
    var newLogState =
        "${oldLogState[0]},${oldLogState[1]},true,${oldLogState[3]}";

    setting.logList[index] = newLogState;
    print("######################## 로그 현황 ########################");
    for (int i = 0; i < setting.logList.length; i++) {
      print("$i : ${setting.logList[i]}");
    }

    pref.setStringList("logList", setting.logList);
  }

  static Future<String> getPrediction() async {
    try {
      await cutFile();
      var result = await uploadFile();
      return result;
    } catch (e) {
      if (e.toString().split(" ")[0] == "DioError") {
        setting.logToServer.add(
            "analyzing : dioError 발생하여 재실행 : ${e.toString().split(" ").sublist(0, 10)}");
        return getPrediction();
      } else if (e.toString().split(":")[0] == "FileSystemException") {
        throw "FileSystemException";
      }
      // 처리 과정 중 에러가 발생했으면 여기서도 그대로 던지기
      rethrow;
      // throw e.toString();
    }
  }

  // 일정 데시벨 이상의 소리가 울렸을 때, 저장된 경로를 반환해주는 함수.
  // fileName에 아무 값도 넣지 않으면 초기 음원파일이 저장된 경로를 반환하고, 파일명이 들어온다면 해당 파일명을 넣어서 반환해준다.
  static Future<String> getPath({fileName = "audio.wav"}) async {
    var appDirectory;
    if (Platform.isAndroid) {
      appDirectory = await getExternalStorageDirectory();
    } else {
      appDirectory = await getApplicationDocumentsDirectory();
    }
    return "${appDirectory.path}/$fileName";
  }

  // 파일을 마지막 1초만 두고 자르고, 자른 파일의 경로를 반환해주는 함수
  static Future<String> cutFile() async {
    try {
      String path = await getPath();
      print("analyzing : 읽어올 경로는 $path");
      setting.logToServer.add("analyzing : 읽어올 경로는 $path");

      // wav package를 이용하여 경로의 파일을 읽기
      var readedFile = await Wav.readFile(path);

      // 읽어오기에 성공했다면 원본 파일을 삭제하여 중복전송 방지

      // 샘플레이트보다 길이가 작으면 1초보다 짧다는 의미이므로 따로 분석 보내지 않고 바로 SignalException 던지기
      if (readedFile.channels[0].length < readedFile.samplesPerSecond) {
        throw SignalException;
      }

      // 전체 길이 - samplesPerSecond부터 슬라이싱하면 마지막 1초간의 데이터만 남게 됨
      for (int i = 0; i < readedFile.channels.length; i++) {
        readedFile.channels[i] = readedFile.channels[i].sublist(
            readedFile.channels[i].length - readedFile.samplesPerSecond,
            readedFile.channels[i].length);
      }

      // 잘린 데이터의 길이 재확인하기, 1초간의 데이터이면 samplesPerSecond와 같은 길이를 가져야 함.
      // 같지 않다면 Exception을 출력하도록 함
      if (readedFile.channels[0].length != readedFile.samplesPerSecond) {
        throw const FormatException("데이터를 제대로 자르지 못했습니다");
      }

      // 파일 저장하기
      path = await getPath(fileName: "cuttedFile.wav");
      print("anaylzing : 저장할 경로는 $path입니다");
      setting.logToServer.add("anaylzing : 저장할 경로는 $path입니다");

      readedFile.writeFile(path);

      return path;
    } catch (e) {
      rethrow;
    }
  }

  // 서버에 로그를 전송한다
  static Future<void> sendLogToServer() async {
    try {
      var dio = Dio();
      // 에러를 전송하려 한다는 메세지 추가
      print("analyzing : 로그 서버로 전송 시도");
      setting.logToServer.add("analyzing : 로그 서버로 전송 시도");

      var formData = FormData.fromMap({
        'logList': setting.logToServer,
        'userName': setting.name,
      });

      var response = await dio.post("$address/uploadLog", data: formData);
      print("analyzing : 서버에 로그를 올렸습니다");
      setting.logToServer.add("analyzing : 서버에 로그를 올렸습니다");
    } catch (e) {
      print("analyzing : 서버와 통신도 실패.. $e");
      setting.logToServer.add("analyzing : 서버와 통신도 실패.. $e");
    }
  }

  // 서버와 상호작용하고 결과를 반환해준다
  static Future<String> uploadFile() async {
    try {
      var pref = await SharedPreferences.getInstance();
      // 기록을 위한 로그파일 불러오기
      String singleLog = "";

      // dio 생성 (http request를 수행해줌)
      var dio = Dio();
      var target = await getPath(fileName: "cuttedFile.wav");
      print("analyzing : 전송할 파일은 $target");
      setting.logToServer.add("analyzing : 전송할 파일은 $target");

      // 파일 경로를 통해 전달할 데이터를 생성함
      // 현재는 파일과 유저명을 전달하는데, 유저명이 겹칠 수 있으므로 유저번호?를 사용해도 좋을 듯!
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(target),
        'userName': setting.name
      });

      // dio객체를 이용해서 서버와 상호작용하는 부분
      var response = await dio.post("$address/uploadFile", data: formData);
      print("analyzing : 서버와 통신에 성공했습니다.");
      setting.logToServer.add("analyzing : 서버와 통신에 성공했습니다.");

      // 통신에 성공했으면 기존 객체 삭제하기
      try {
        File(target).delete();
      } catch (e) {
        true;
      }

      // 서버가 반환해준 결과를 result에 저장
      var result = response.data['prediction'];
      var message = response.data['message'];

      // 로그에 분석 결과와 분석 시간 삽입, 확인 여부는 일단 False로 하고 넣기
      singleLog += "$result,";
      singleLog += "${DateFormat("HH시 mm분 ss초").format(DateTime.now())},";
      singleLog += "false,";
      singleLog += "${getMinuteValue(DateTime.now())}";
      setting.logList.add(singleLog);

      // 갯수가 10개가 넘어가면 하나씩 지우기
      if (setting.logList.length > 10) {
        setting.logList.removeAt(0);
      }

      // // @@@@@@@@ For Release 1.1
      // // 판단 이후 너무 자주 시끄럽다면 데시벨 10 높이
      // // 이제 자주 시끄럽지 않다면 데시벨 10 다시 내리기
      // if (raiseDecibelCheck() && !dB_raised) {
      //   dB_raised = true;
      //   setting.dB += 10;
      // } else if (!raiseDecibelCheck() && dB_raised) {
      //   dB_raised = false;
      //   setting.dB -= 10;
      // }

      // 이후 SharedPreference에 저장
      pref.setStringList("logList", setting.logList);
      //반환된 값이 null이라면 분석에 실패한 것이므로 exception을 반환
      if (result == "unknown") {
        notification.showNotification(
            "소리 알림", "${setting.dB.round()} dB 이상의 소리가 발생했습니다. 주변을 확인하세요");
        throw SignalException;
      } else {
        notification.showNotification("소리 알림", "$result가 들립니다. 주의하세요");
        return result.toString();
      }
    } catch (e) {
      rethrow;
    }
  }

  static bool raiseDecibelCheck() {
    int length = setting.logList.length;
    try {
      // 가장 최근에 발생한 큰 소리의 시간을 가져오기
      String timeLatest = setting.logList[length - 1].split(",")[3];
      // 이것보다 4개 이전에 발생한
      // 이 때 기록된 것이 5개 이하라면 여기서 오류가 날 수 있으므로 try-catch
      String timePrevious = setting.logList[length - 5].split(",")[3];

      // 비교를 위해 int형으로 변환
      int minLatest = int.parse(timeLatest);
      int minPrevious = int.parse(timePrevious);

      // 둘을 뺐을 때 10이하면, 데시벨 이상의 소리가 10분 이내에 5번 발생한 것이므로 true를 반환해서 내리도록, 아니면 false 반환
      if (minLatest - minPrevious < 10) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // 에러가 났을 경우에는 기록된 것이 5개 이하인 경우일 것이므로 false 반환
      return false;
    }
  }

  // DateTime 자로형을 Minute단위로 바꿔서 반환
  static int getMinuteValue(DateTime time) {
    int forReturn = 0;
    forReturn += (int.parse(DateFormat("dd").format(DateTime.now())) * 60 * 24);
    forReturn += (int.parse(DateFormat("HH").format(DateTime.now())) * 60);
    forReturn += (int.parse(DateFormat("mm").format(DateTime.now())));
    return forReturn;
  }

  /// @@@@@@ 저장되었던 logList를 로그에 사용할 String의 리스트로 반환해준다. @@@@@@@
  /// Example --------------------------------------------------------
  /// ["사이렌 소리가 17시 30분 24초에 발생하였습니다. 확인하셨나요?",
  /// "차량 급정거 소리가 18시 31분 02초에 발생하였습니다. 확인하셨나요?"]
  /// ————————————————————————————————
  static List<String> getLogString() {
    List<String> logList = [];
    for (int i = 0; i < setting.logList.length; i++) {
      var splitted = setting.logList[i].split(",");
      // if (splitted[0] != "unknown" && splitted[2] == "false") {
      if (splitted[0] != "unknown") {
        logList.add("${splitted[0]}가 ${splitted[1]}에 발생하였습니다.");
      }
    }
    return logList;
  }

  // static void showPopup(BuildContext context) {
  //   showDialog(
  //       context: context,
  //       barrierDismissible: true, // 창 바깥쪽을 클릭하면 사라짐
  //       builder: (BuildContext context) {
  //         return const ModelPopup();
  //       });
  // }

  static void showPopup(BuildContext context) {
    String object = "분석중입니다";
    String title = "소리 감지";
    String message = "닫기";

    void Function()? defaultPress() {
      Navigator.pop(context);
      context.read<RecordModule>().record();
      return null;
    }

    Color color = Colors.black;
    // 분석 중입니다.
    late Widget returnWidget = oneButtonDialog(
        context, title, object, message, defaultPress,
        color: color);
    showDialog(
        context: context,
        barrierDismissible: true, // 창 바깥쪽을 클릭하면 사라짐
        builder: (BuildContext context) {
          Future.delayed(const Duration(seconds: 10), () {
            Navigator.of(context, rootNavigator: true).pop();
            context.read<RecordModule>().record();
          });
          return returnWidget;
        });

    Future<String> prediction = FunctionClass.getPrediction();
    prediction.then((val) async {
      // --------------- cases[2] 전체 화면 알림 설정이 true이면 알림을 울리게 ---------------
      MissedAlertState.onScreen = false;
      title = "분석 완료";
      returnWidget = oneButtonDialog(
          context, title, "결과를 출력하는 중입니다", message, defaultPress,
          color: Colors.green);
      if (cases[2]) {
        if (Platform.isAndroid) {
          DateTime now = DateTime.now();
          DateTime time = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
            now.second,
          );
          context.read<AlarmProvider>().setAlarm(time, val);
          await AlarmScheduler.scheduleRepeatable(time);
          // Navigator.pop(context);
        } else {
          returnWidget = AlarmScreen(alarmName: val);
          // Navigator.pop(context);
        }
      } else {
        returnWidget = oneButtonDialog(
            context, title, val, message, defaultPress,
            color: Colors.green);
        // Navigator.pop(context);
        showDialog(
            context: context,
            barrierDismissible: true, // 창 바깥쪽을 클릭하면 사라짐
            builder: (BuildContext context) {
              Future.delayed(const Duration(seconds: 10), () {
                debugPrint('debugging : ${DateTime.now().second}');
                Navigator.of(context, rootNavigator: true).pop();
                context.read<RecordModule>().record();
              });
              return returnWidget;
            });
      }
    }).catchError((error) async {
      // SignalException은 무슨 소리인지 인지하지 못했을 경우임. 이때는 에러는 아니므로 다른 처리
      MissedAlertState.onScreen = false;
      if (error.toString() == "SignalException") {
        if (cases[2]) {
          if (Platform.isAndroid) {
            DateTime now = DateTime.now();
            DateTime time = DateTime(
              now.year,
              now.month,
              now.day,
              now.hour,
              now.minute,
              now.second,
            );
            context
                .read<AlarmProvider>()
                .setAlarm(time, "${dB.round()} dB 이상의 소리");
            await AlarmScheduler.scheduleRepeatable(time);
            // Navigator.pop(context);

            title = "분석 완료";
          } else {
            returnWidget =
                AlarmScreen(alarmName: "${int.parse(dB.toString())} dB 이상의 소리");
            // Navigator.pop(context);
          }
        } else {
          title = "분석 완료";
          returnWidget = oneButtonDialog(
              context, title, "${dB.round()} dB 이상의 소리", message, defaultPress,
              color: Colors.green);
          showDialog(
              context: context,
              barrierDismissible: true, // 창 바깥쪽을 클릭하면 사라짐
              builder: (BuildContext context) {
                Future.delayed(const Duration(seconds: 10), () {
                  debugPrint('debugging : ${DateTime.now().second}');
                  Navigator.of(context, rootNavigator: true).pop();
                  context.read<RecordModule>().record();
                });
                return returnWidget;
              });
        }
      } else {
        print("analyzing : 에러가 발생했습니다 : $error");
        logToServer.add("analyzing : 에러가 발생했습니다 : $error");
        FunctionClass.sendLogToServer();
        defaultPress();
      }
    });
  }

  static void showModelProcess(BuildContext context) {
    void Function()? defaultPress() {
      Navigator.pop(context);
      context.read<RecordModule>().record();
      return null;
    }

    String object = "분석중입니다";
    String title = "소리 감지";
    String message = "닫기";
    Color color = Colors.black;

    Widget returnWidget = oneButtonDialog(
        context, title, "결과를 출력하는 중입니다", message, defaultPress,
        color: Colors.green);

    Future<String> prediction = FunctionClass.getPrediction();

    ToastContext().init(context);
    Toast.show('소리를 분석 중입니다.',
        duration: Toast.lengthShort, gravity: Toast.bottom);

    prediction.then((val) async {
      // --------------- cases[2] 전체 화면 알림 설정이 true이면 알림을 울리게 ---------------
      // MissedAlertState.onScreen = false;
      Toast.show('분석을 완료하였습니다.', duration: 5, gravity: Toast.bottom);

      if (cases[2]) {
        if (Platform.isAndroid) {
          DateTime now = DateTime.now();
          DateTime time = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
            now.second,
          );
          context.read<AlarmProvider>().setAlarm(time, val);
          await AlarmScheduler.scheduleRepeatable(time);
          // Navigator.pop(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => AlarmScreen(alarmName: val),
            ),
          );
        }
      } else {
        if (val == "null") {
          val = '소리';
        }
        Toast.show('$val가 감지되었습니다.', duration: 5, gravity: Toast.bottom);
        Timer(const Duration(seconds: 5), () {
          context.read<RecordModule>().record();
        });
      }
    }).catchError((error) async {
      // SignalException은 무슨 소리인지 인지하지 못했을 경우임. 이때는 에러는 아니므로 다른 처리
      MissedAlertState.onScreen = false;
      if (error.toString() == "SignalException") {
        if (cases[2]) {
          if (Platform.isAndroid) {
            DateTime now = DateTime.now();
            DateTime time = DateTime(
              now.year,
              now.month,
              now.day,
              now.hour,
              now.minute,
              now.second,
            );
            context
                .read<AlarmProvider>()
                .setAlarm(time, "${dB.round()} dB 이상의 소리");
            await AlarmScheduler.scheduleRepeatable(time);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => AlarmScreen(
                    alarmName: "${int.parse(dB.toString())} dB 이상의 소리"),
              ),
            );
          }
        } else {
          Toast.show('${dB.round()} dB 이상의 소리의 소리를 감지하였습니다.',
              duration: 5, gravity: Toast.bottom);
          Timer(const Duration(seconds: 5), () {
            context.read<RecordModule>().record();
          });
        }
      } else {
        Toast.show('에러가 발생했습니다. 5초 뒤 상시모드가 다시 시작됩니다.',
            duration: 5, gravity: Toast.bottom);
        Timer(const Duration(seconds: 5), () {
          context.read<RecordModule>().record();
        });

        print("analyzing : 에러가 발생했습니다 : $error");
        logToServer.add("analyzing : 에러가 발생했습니다 : $error");
        FunctionClass.sendLogToServer();
      }
    });
  }
}

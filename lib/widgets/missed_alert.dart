import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hear_for_you/constants.dart';
import '../service/functions.dart';

import '../constants.dart' as constants;

// 미확인 알림 팝업

class MissedAlert extends StatefulWidget {
  const MissedAlert({Key? key}) : super(key: key);

  @override
  State<MissedAlert> createState() => MissedAlertState();
}

class MissedAlertState extends State<MissedAlert> {
  late int missedAlertNum;
  late int logCount;

  // 스크린에 나와있는지 여부를 판단하는 bool형 변수
  static bool onScreen = false;

  @override
  initState() {
    super.initState();
    missedAlertNum = FunctionClass.logsToShown();
    logCount = FunctionClass.howManyLogsLeft();
    print("출력할 로그는 $missedAlertNum 번째 값입니다");
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    Timer(const Duration(milliseconds: 500), () {
      if (onScreen) {
        missedAlertNum = FunctionClass.logsToShown();
        logCount = FunctionClass.howManyLogsLeft();
        setState(() {});
      }
    });

    return Stack(children: [
      logCount > 1
          ? Positioned(
              left: 25,
              right: 25,
              bottom: 100,
              child: Container(
                width: screenWidth,
                height: 120,
                padding: const EdgeInsets.only(
                    top: 5, bottom: 12, left: 15, right: 15),
                decoration: BoxDecoration(
                  color: darkMode
                      ? kGrey8.withOpacity(0.6)
                      : kWhite.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: darkMode ? kBlack : kBlack.withOpacity(0.1),
                      spreadRadius: 3,
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            )
          : Container(),
      Positioned(
        left: 15,
        right: 15,
        bottom: 90,
        // 1. 외부 컨테이너
        child: Container(
          width: screenWidth,
          height: 120,
          padding:
              const EdgeInsets.only(top: 5, bottom: 12, left: 15, right: 15),
          decoration: BoxDecoration(
            color: darkMode ? kGrey8.withOpacity(0.8) : kWhite.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: darkMode ? kBlack : kBlack.withOpacity(0.1),
                spreadRadius: 3,
                blurRadius: 15,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // 2. 팝업 이름와 팝업 끄기 버튼
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.centerLeft,
                child: Text(
                  (missedAlertNum != -1) ? '최근 미확인 알림' : "미확인 알림이 없습니다",
                  style: TextStyle(fontSize: kXS, color: kGrey5),
                ),
              ),
              // 3. 알림 이름과 알림이 발생된 시각
              Container(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'PretendardBold',
                      fontSize: kS,
                      color: darkMode ? kWhite : kBlack,
                    ),
                    children: [
                      TextSpan(
                          text: missedAlertNum != -1
                              ? constants.logList[missedAlertNum].split(",")[0]
                              : "",
                          style: TextStyle(fontSize: kL)),
                      TextSpan(
                        text: missedAlertNum != -1
                            ? " (${constants.logList[missedAlertNum].split(",")[1]})"
                            : "",
                      )
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // 4. 확인 버튼
              missedAlertNum != -1
                  ? Row(
                      children: [
                        Text(
                          '확인하셨나요?',
                          style: TextStyle(
                              fontSize: kM, color: darkMode ? kWhite : kBlack),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            FunctionClass.changeLogState(missedAlertNum);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '네, 확인했어요',
                            style: TextStyle(fontSize: kS, color: kMain),
                          ),
                        ),
                      ],
                    )
                  : Row(),
            ],
          ),
        ),
      ),
      logCount > 0
          ? Positioned(
              right: 10,
              bottom: 190,
              child: Container(
                width: logCount < 10 ? 30 : null,
                height: 30,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: darkMode ? kBlack : kBlack.withOpacity(0.1),
                      spreadRadius: 3,
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  "$logCount",
                  style: TextStyle(color: kWhite, fontSize: kM),
                ),
              ),
            )
          : Container(),
    ]);
  }
}

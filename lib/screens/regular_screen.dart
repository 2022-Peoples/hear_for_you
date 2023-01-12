import 'package:flutter/material.dart';
import 'package:hear_for_you/modules/regular_module.dart';
import 'package:hear_for_you/screens/tutorial_screen.dart';
import 'package:hear_for_you/service/full_screen_alert/view/alarm_screen.dart';
import 'dart:io' show Platform;
import 'package:hear_for_you/widgets/missed_alert.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../service/permission_check.dart';
import 'package:provider/provider.dart';

import '../constants.dart';

// 상시모드 페이지

class RegularScreen extends StatefulWidget {
  const RegularScreen({Key? key}) : super(key: key);
  @override
  State<RegularScreen> createState() => RegularScreenState();
}

class RegularScreenState extends State<RegularScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation =
      Tween(begin: 0.0, end: 100.0).animate(controller);
  static bool needPopup = false;

  // 애니메이션 시작
  // ++ 12월 27일 알람설정 확인하는 부분도 추가 ++
  @override
  void initState() {
    super.initState();

    // regularscreen에서는 missedalert가 필요하므로 true로 교체
    MissedAlertState.onScreen = true;

    // 현재 안드로이드면
    if (Platform.isAndroid) {
      PermissionCheckClass.AndroidAlertPermissionCheck(context);
      PermissionCheckClass.AndroidSystemAlertWindowPermissionCheck(context);
      PermissionCheckClass.AndroidMicPermissionCheck(context);
    } else {
      // ios라면
      PermissionCheckClass.IOSAlertPermissionCheck(context);
      PermissionCheckClass.IOSMicPermissionCheck(context);
      PermissionCheckClass.IOSRecognitionPermissionCheck(context);
    }
    controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    animation.addListener(() {
      setState(() {});
    });

    if (isInit) {
      context.read<RecordModule>().initState();
      if (regularValue) {
        context.read<RecordModule>().record();
      }
    }
  }

  // 애니메이션 종료
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenWidth = MediaQuery.of(context).size.width;

    final waveController = SiriWaveController(
      amplitude: regularValue ? 1 : 0,
      frequency: 6,
      speed: 0.09,
      color: kWhite,
    );

    return Consumer<RecordModule>(builder: (context, state, child) {
      return Scaffold(
        backgroundColor: darkMode ? kBlack : kGrey1,
        body: Stack(
          children: [
            Column(
              children: [
                // 1. 상시모드 상태 표시줄
                Padding(
                  padding: EdgeInsets.only(
                      top: 5 + statusBarHeight, bottom: 5, left: 5, right: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1-1. 도움말 버튼 (현재 임시로 알림 화면 연결)
                      IconButton(
                        icon: Icon(
                          Icons.help_rounded,
                          size: 24,
                          color: darkMode ? kWhite : kBlack,
                        ),
                        tooltip: "도움말 다시 보기",
                        padding: const EdgeInsets.all(10),
                        onPressed: () async {
                          // 튜토리얼 페이지
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const TutorialScreen()));
                        },
                      ),
                      // 1-2. 상시모드 상태
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '상시모드 ',
                              style: TextStyle(
                                fontSize: kXL,
                                fontFamily: 'PretendardBold',
                                color: darkMode ? kWhite : kBlack,
                              ),
                            ),
                            Text(
                              regularValue ? '켜짐' : '꺼짐',
                              style: TextStyle(
                                fontSize: kXL,
                                fontFamily: 'PretendardBold',
                                color: regularValue ? kMain : kGrey5,
                              ),
                            )
                          ],
                        ),
                      ),
                      // 1-3. 대칭 맞추기용 아이콘
                      IconButton(
                        icon: const Icon(
                          Icons.help_rounded,
                          size: 24,
                          color: Colors.transparent,
                        ),
                        padding: const EdgeInsets.all(15),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // 2. 원형 회전 애니메이션
                Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    // 2-1. 애니메이션 외부 (실제 돌아가는 부분)
                    Container(
                      width: screenWidth * 0.7,
                      height: screenWidth * 0.7,
                      margin: const EdgeInsets.only(top: 60),
                      child: SfRadialGauge(
                        axes: <RadialAxis>[
                          RadialAxis(
                            minimum: 0,
                            maximum: 100,
                            showLabels: false,
                            showTicks: false,
                            startAngle: 270,
                            endAngle: 270,
                            axisLineStyle: AxisLineStyle(
                              thickness: 0.08,
                              color:
                                  darkMode ? kGrey9 : kGrey2.withOpacity(0.6),
                              thicknessUnit: GaugeSizeUnit.factor,
                            ),
                            pointers: <GaugePointer>[
                              RangePointer(
                                value: regularValue ? animation.value : 0,
                                width: 0.08,
                                sizeUnit: GaugeSizeUnit.factor,
                                gradient: SweepGradient(
                                  colors: <Color>[
                                    kMain,
                                    kMain.withOpacity(0.5)
                                  ],
                                  stops: const <double>[0.35, 0.85],
                                ),
                                cornerStyle: CornerStyle.bothCurve,
                                enableAnimation: true,
                                animationDuration: 100,
                                animationType: AnimationType.linear,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    // 2-2. 애니메이션 내부 (웨이브폼이 그려져있는 이미지)
                    Container(
                      width: screenWidth * 0.55,
                      height: screenWidth * 0.55,
                      margin: const EdgeInsets.only(top: 60),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [kMain, kMain.withOpacity(0.5)]),
                      ),
                      //2-2-1. 웨이브폼 (상시모드 상태에 따라 모양 달라짐)
                      child: SiriWave(
                        controller: waveController,
                        options: SiriWaveOptions(
                          width: screenWidth * 0.55,
                          height: screenWidth * 0.55,
                          backgroundColor: Colors.transparent,
                        ),
                        style: SiriWaveStyle.ios_7,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 60),
                // 3. 소리를 듣고 있습니다. (큰 의미 없음, 보조 표식)
                regularValue
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Container(
                              color: darkMode ? kBlack : kGrey1,
                              child: LoadingAnimationWidget.waveDots(
                                  color: darkMode ? kWhite : kBlack,
                                  size: 30.0),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '소리를 듣고 있습니다',
                              style: TextStyle(
                                  color: darkMode ? kWhite : kBlack,
                                  fontSize: kXS),
                            ),
                          ])
                    : Text(
                        '상시모드가 꺼져있습니다.',
                        style: TextStyle(
                            color: darkMode ? kWhite : kBlack, fontSize: kXS),
                      ),
              ],
            ),
            // 4. 미확인 알림 팝업 자리
            const MissedAlert(),
          ],
        ),
      );
    });
  }
}

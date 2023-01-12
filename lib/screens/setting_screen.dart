// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hear_for_you/screens/profile_notice.dart';
import 'package:hear_for_you/screens/settings/data_setting.dart';
import 'package:hear_for_you/screens/settings/decibel_setting.dart';
import 'package:hear_for_you/screens/settings/display_setting.dart';
import 'package:hear_for_you/screens/settings/notification_setting.dart';
import 'package:hear_for_you/widgets/custom_card.dart';
import 'package:hear_for_you/widgets/missed_alert.dart';
import 'package:hear_for_you/widgets/profile_modal.dart';
import 'package:hear_for_you/constants.dart';
import 'package:hear_for_you/widgets/setting_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/permission_check.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
// 설정 페이지
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';
import 'package:hear_for_you/modules/regular_module.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  void setRegularValue(bool regularValue) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool('regularValue', regularValue);
  }

  @override
  initState() {
    super.initState();
    MissedAlertState.onScreen = false;
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);

    // 설정 타이틀의 스타일
    TextStyle settingTitleStyle = TextStyle(
      fontFamily: 'PretendardBold',
      fontSize: kM,
      color: darkMode ? kWhite : kBlack,
    );

    Icon chevronIcon =
        Icon(Icons.chevron_right_rounded, size: 22, color: kGrey5);

    // 각 설정 목록, 누르면 해당 페이지로 이동
    Widget settingItem(title, action, screen) {
      return TextButton(
        onPressed: () {
          Navigator.push(
                  context, MaterialPageRoute(builder: (context) => screen))
              .then((value) => setState(
                    () {},
                  ));
        },
        style: TextButton.styleFrom(
          primary: kGrey5,
        ),
        child: Row(
          children: [
            title,
            const Spacer(),
            action,
          ],
        ),
      );
    }

    void setCases(int n, bool value) async {
      final SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setBool('case${n + 1}', value);
      print("case${n + 1} changed! : $value");
    }

    List<String> notis = ["푸시 알림 ", "플래시 알림 ", "전체 화면 알림 "];
    Widget notiItem(n) {
      return InkWell(
        onTap: () async {
          setState(() {
            cases[n] = !cases[n];
            setCases(n, cases[n]);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            children: [
              Text(notis[n], style: settingTitleStyle),
              cases[n]
                  ? Text(
                      '켜짐',
                      style: TextStyle(
                        fontFamily: 'PretendardBold',
                        fontSize: kM,
                        color: kMain,
                      ),
                    )
                  : Text(
                      '꺼짐',
                      style: TextStyle(
                        fontFamily: 'PretendardBold',
                        fontSize: kM,
                        color: kGrey5,
                      ),
                    ),
              const Spacer(),
              Transform.scale(
                scale: 0.9,
                child: SizedBox(
                  height: 10,
                  child: CupertinoSwitch(
                    activeColor: kMain,
                    value: cases[n],
                    onChanged: (value) {},
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<RecordModule>(builder: (context, state, child) {
      return Scaffold(
        backgroundColor: darkMode ? kBlack : kGrey1,
        // 1. 앱바
        appBar: settingAppbar('설정', context, isLeading: false),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            margin: const EdgeInsets.only(bottom: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. 개인 설정 영역
                customCard(
                  '개인 설정',
                  Column(
                    children: [
                      // 2-1. 사용자 이름
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'PretendardBold',
                              fontSize: kXL + 3,
                              color: kMain,
                            ),
                          ),
                          Text(
                            ' 님',
                            style: TextStyle(
                              fontFamily: 'PretendardBold',
                              fontSize: kXL,
                              color: darkMode ? kWhite : kBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // 2-2. 사용자 장애 정도 설정
                      GestureDetector(
                        child: Container(
                          color: darkMode ? kGrey9 : kWhite,
                          child: Row(
                            children: [
                              Text(
                                profileItems[profileValue],
                                style: TextStyle(
                                  fontSize: kS,
                                  color: darkMode ? kWhite : kBlack,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return const ProfileNotice();
                                      });
                                },
                                tooltip: "장애정도 설정 안내 보기",
                                icon: Icon(
                                  Icons.help_rounded,
                                  color: kMain,
                                  size: 20,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                constraints: const BoxConstraints(),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 22,
                                color: kGrey5,
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) =>
                                  profileModalBuilder(context)).then(
                            (value) => setState(() {}),
                          );
                        },
                      ),
                    ],
                  ),
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
                ),
                // 3. 상시모드 설정 영역
                customCard(
                  '상시모드 설정',
                  Column(
                    children: [
                      // 3-1. 상시모드 켜짐, 꺼짐 + 스위치
                      InkWell(
                        onTap: () async {
                          var result = await Permission.speech.isGranted;
                          setState(() {
                            if (result) {
                              regularValue = !regularValue;
                              setRegularValue(regularValue);
                              if (regularValue) {
                                context.read<RecordModule>().initState();
                                Toast.show('5초 뒤 상시모드가 다시 시작됩니다.',
                                    duration: Toast.lengthLong,
                                    gravity: Toast.bottom);
                                context.read<RecordModule>().record();
                              } else {
                                context.read<RecordModule>().disposeState();
                              }
                            } else {
                              if (Platform.isAndroid) {
                                PermissionCheckClass.AndroidMicPermissionCheck(
                                    context);
                                PermissionCheckClass
                                    .AndroidRecognitionPermissionCheck(context);
                              } else {
                                PermissionCheckClass
                                    .IOSRecognitionPermissionCheck(context);
                              }
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 8),
                          child: Row(
                            children: [
                              Text(
                                '상시모드 ',
                                style: settingTitleStyle,
                              ),
                              regularValue
                                  ? Text(
                                      '켜짐',
                                      style: TextStyle(
                                        fontFamily: 'PretendardBold',
                                        fontSize: kM,
                                        color: kMain,
                                      ),
                                    )
                                  : Text(
                                      '꺼짐',
                                      style: TextStyle(
                                        fontFamily: 'PretendardBold',
                                        fontSize: kM,
                                        color: kGrey5,
                                      ),
                                    ),
                              const Spacer(),
                              Transform.scale(
                                scale: 0.9,
                                child: SizedBox(
                                  height: 10,
                                  child: CupertinoSwitch(
                                    activeColor: kMain,
                                    value: regularValue,
                                    onChanged: (value) {},
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      spacer(const EdgeInsets.only(bottom: 2)),
                      // 3-2. 데시벨 설정 페이지로 이동
                      settingItem(
                        Text(
                          '데시벨 설정',
                          style: settingTitleStyle,
                        ),
                        Row(
                          children: [
                            Text(
                              dB.toString(),
                              style: TextStyle(fontSize: kM, color: kMain),
                            ),
                            Text(
                              ' dB',
                              style: TextStyle(
                                fontSize: kM,
                                color: darkMode ? kWhite : kBlack,
                              ),
                            ),
                            chevronIcon,
                          ],
                        ),
                        const DecibelSetting(),
                      ),
                    ],
                  ),
                  const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                ),
                // 4. 알림 설정 영역
                customCard(
                  "알림 설정",
                  Column(
                    children: [
                      notiItem(0),
                      spacer(const EdgeInsets.only(bottom: 2)),
                      Platform.isAndroid
                          ? Column(
                              children: [
                                notiItem(1),
                                spacer(const EdgeInsets.only(bottom: 2)),
                              ],
                            )
                          : Container(),
                      notiItem(2),
                    ],
                  ),
                  const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                ),
                // customCard(
                //   '알림 설정',
                //   Column(
                //     children: [
                //       // 4-1. case0, 긴급재난 알림 페이지로 이동 + 켬, 끔 표시
                //       settingItem(
                //         Text(caseTitle[0], style: settingTitleStyle),
                //         Row(
                //           children: [
                //             Text(
                //               cases[0] ? '켬' : '끔',
                //               style: TextStyle(
                //                 fontSize: kM,
                //                 color: cases[0] ? kMain : kGrey5,
                //               ),
                //             ),
                //             chevronIcon,
                //           ],
                //         ),
                //         const NotificationSetting(num: 0),
                //       ),
                //       spacer(const EdgeInsets.only(bottom: 5)),
                //       // 4-2. case1, 실외위험 알림 페이지로 이동 + 켬, 끔 표시
                //       settingItem(
                //         Text(caseTitle[1], style: settingTitleStyle),
                //         Row(
                //           children: [
                //             Text(
                //               cases[1] ? '켬' : '끔',
                //               style: TextStyle(
                //                 fontSize: kM,
                //                 color: cases[1] ? kMain : kGrey5,
                //               ),
                //             ),
                //             chevronIcon,
                //           ],
                //         ),
                //         const NotificationSetting(num: 1),
                //       ),
                //       spacer(const EdgeInsets.only(bottom: 5)),
                //       // 4-3. case2, 실내위험 알림 페이지로 이동 + 켬, 끔 표시
                //       settingItem(
                //         Text(caseTitle[2], style: settingTitleStyle),
                //         Row(
                //           children: [
                //             Text(
                //               cases[2] ? '켬' : '끔',
                //               style: TextStyle(
                //                 fontSize: kM,
                //                 color: cases[2] ? kMain : kGrey5,
                //               ),
                //             ),
                //             chevronIcon,
                //           ],
                //         ),
                //         const NotificationSetting(num: 2),
                //       ),
                //     ],
                //   ),
                //   const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                // ),
                // // 5. 화면 설정 영역
                customCard(
                  '기타 설정',
                  // 5-1. 화면 설정 페이지로 이동
                  settingItem(
                    Text(
                      '화면 설정',
                      style: settingTitleStyle,
                    ),
                    chevronIcon,
                    const DisplaySetting(),
                  ),
                  const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                ),
                // 6. 앱 정보 공시 영역
                customCard(
                  '',
                  settingItem(
                    Text(
                      '정보',
                      style: settingTitleStyle,
                    ),
                    chevronIcon,
                    const DataSetting(),
                  ),
                  const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  nontitle: true,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

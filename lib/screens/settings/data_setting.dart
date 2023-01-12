import 'package:flutter/material.dart';
import 'package:hear_for_you/screens/login_screen.dart';
import 'package:hear_for_you/screens/settings/developers.dart';
import 'package:hear_for_you/screens/settings/privacy_policy.dart';
import 'package:hear_for_you/widgets/custom_card.dart';
import 'package:hear_for_you/widgets/custom_dialog.dart';
import 'package:hear_for_you/widgets/setting_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants.dart';

class DataSetting extends StatefulWidget {
  const DataSetting({Key? key}) : super(key: key);

  @override
  State<DataSetting> createState() => _DataSettingState();
}

class _DataSettingState extends State<DataSetting> {
  @override
  Widget build(BuildContext context) {
    String version = "1.1.0";

    // 설정 타이틀의 스타일
    TextStyle settingTitleStyle(color) {
      return TextStyle(
        fontFamily: 'PretendardBold',
        fontSize: kM,
        color: color,
      );
    }

    Icon chevronIcon =
        Icon(Icons.chevron_right_rounded, size: 22, color: kGrey5);

    // 각 설정 목록, 누르면 해당 페이지로 이동
    Widget settingItem(title, action, screen) {
      return TextButton(
        onPressed: screen != null
            ? () {
                if (screen == "license") {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          LicensePage(applicationVersion: version)));
                } else if (screen == "email") {
                  showDialog(
                      context: context,
                      builder: (builder) {
                        return oneButtonDialog(
                          context,
                          "문의하기",
                          "문의 사항이 있는 경우,\n아래 이메일로 연락바랍니다 :)\npeoples221120@gmail.com",
                          "확인",
                          () {
                            Navigator.pop(context);
                          },
                        );
                      });
                } else {
                  Navigator.push(context,
                          MaterialPageRoute(builder: (context) => screen))
                      .then((value) => setState(
                            () {},
                          ));
                }
              }
            : null,
        style: TextButton.styleFrom(
          primary: kGrey5,
        ),
        child: Row(
          children: [
            Text(title, style: settingTitleStyle(darkMode ? kWhite : kBlack)),
            const Spacer(),
            screen != null ? action : Text(version, style: TextStyle(color: kGrey5)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: darkMode ? kBlack : kGrey1,
      appBar: settingAppbar('정보', context),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            customCard(
              '',
              Column(
                children: [
                  settingItem(
                    '오픈소스 라이선스',
                    chevronIcon,
                    "license",
                  ),
                  spacer(const EdgeInsets.only(bottom: 5)),
                  settingItem(
                    '개인정보 정책',
                    chevronIcon,
                    const PrivacyPolicy(),
                  ),
                  spacer(const EdgeInsets.only(bottom: 5)),
                  settingItem(
                    '문의하기',
                    chevronIcon,
                    "email",
                  ),
                  spacer(const EdgeInsets.only(bottom: 5)),
                  settingItem(
                    '만든 사람들',
                    chevronIcon,
                    const Developers(),
                  ),
                  spacer(const EdgeInsets.only(bottom: 5)),
                  settingItem(
                    '버전 정보',
                    chevronIcon,
                    null,
                  ),
                ],
              ),
              const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              nontitle: true,
            ),
            customCard(
              '',
              TextButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return twoButtonDialog(
                          context,
                          "잠시만요!",
                          "$name님의 모든 정보가 초기화됩니다.\n정말 삭제하시나요?",
                          "아니요",
                          "네, 삭제할래요",
                          () {
                            Navigator.of(context).pop();
                          },
                          () async {
                            // 모든 SharedPrefrences 초기화
                            final SharedPreferences pref =
                                await SharedPreferences.getInstance();
                            pref.clear();
                            // constants 초기화
                            name = '';
                            profileValue = 0;
                            regularValue = false;
                            dB = 60;
                            darkMode = false;
                            selectedColor = 7;
                            fontSizes = [true, true, true];
                            fontSizeId = 1;
                            cases = [true, true, true];
                            caseDetails = [
                              [true, true, true],
                              [true, true, true],
                              [true, true, true]
                            ];
                            logList = [];
                            kMain = colorChart[selectedColor];

                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          isDelete: true,
                        );
                      });
                },
                style: TextButton.styleFrom(
                  primary: kGrey5,
                ),
                child: Row(
                  children: [
                    Text("내 정보 삭제", style: settingTitleStyle(Colors.red)),
                    const Spacer(),
                  ],
                ),
              ),
              const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              nontitle: true,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hear_for_you/modules/voice_module.dart';
import 'package:hear_for_you/widgets/chat_modal.dart';
import 'package:hear_for_you/widgets/missed_alert.dart';
import 'package:hear_for_you/widgets/voice_mode_select.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import '../constants.dart';
import '../service/permission_check.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({Key? key}) : super(key: key);

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late bool isInput;
  bool isOpen = false;

  final TextEditingController textController = TextEditingController();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  initState() {
    super.initState();
    MissedAlertState.onScreen = false;
    if (Platform.isAndroid) {
      // 안드로이드라면
      PermissionCheckClass.AndroidRecognitionPermissionCheck(context);
    } else {
      // IOS 라면
      PermissionCheckClass.IOSRecognitionPermissionCheck(context);
    }
    isEmpty = true;
    isInput = false;

    context.read<VoiceModule>().initSpeech();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double navigationBarHeight = MediaQuery.of(context).padding.bottom;

    // 채팅 메세지가 담길 버블
    Widget bubble(str, user) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          user ? const Spacer() : const SizedBox(),
          Container(
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: screenWidth * 0.65),
            decoration: BoxDecoration(
              color: user
                  ? kMain
                  : darkMode
                      ? kGrey8
                      : kGrey2,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomRight: user ? Radius.zero : const Radius.circular(20),
                bottomLeft: user ? const Radius.circular(20) : Radius.zero,
              ),
            ),
            child: Text(
              str,
              style: TextStyle(
                  color: user
                      ? kWhite
                      : darkMode
                          ? kWhite
                          : kGrey5,
                  fontSize: kS),
            ),
          ),
          user ? const SizedBox() : const Spacer(),
        ],
      );
    }

    // 입력 필드 전송 관리, 사용자 발화 추가
    void _handleSubmitted(String text) {
      textController.clear();
      if (text != "") {
        setState(() {
          voiceScreenChat.insert(0, [text, true]);
        });
      }
    }

    return Consumer<VoiceModule>(builder: (context, state, child) {
      return Scaffold(
        backgroundColor: darkMode ? kBlack : kGrey1,
        body: Container(
          padding: EdgeInsets.only(top: statusBarHeight),
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              // body
              isEmpty
                  ? SizedBox(
                      width: screenWidth,
                      height: screenHeight,
                      child: Center(
                        child: Text(
                          '음성모드 화면입니다.\n하단의 버튼을 눌러 대화를 시작하세요.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: kGrey5, fontSize: kS, height: 2),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        SizedBox(width: screenWidth, height: 50),
                        Flexible(
                            child: SingleChildScrollView(
                          reverse: true,
                          child: Screenshot(
                            controller: screenshotController,
                            child: Container(
                              padding: const EdgeInsets.only(top: 10),
                              color: darkMode ? kBlack : kGrey1,
                              child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  reverse: true,
                                  itemCount: voiceScreenChat.length,
                                  itemBuilder: (BuildContext context, idx) {
                                    return Container(
                                      padding: EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                          bottom: (idx + 1 <
                                                      voiceScreenChat.length) &&
                                                  (voiceScreenChat[idx][1] !=
                                                      voiceScreenChat[idx + 1]
                                                          [1])
                                              ? 10
                                              : 5),
                                      alignment: voiceScreenChat[idx][1]
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: bubble(voiceScreenChat[idx][0],
                                          voiceScreenChat[idx][1]),
                                    );
                                  }),
                            ),
                          ),
                        )),
                        Container(
                          margin: EdgeInsets.only(bottom: isOpen ? 60 : 140),
                          width: screenWidth,
                        ),
                      ],
                    ),
              // head
              isEmpty
                  ? const SizedBox()
                  : Container(
                      height: 50,
                      color: darkMode ? kBlack : kGrey1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Spacer(),
                          Container(
                            margin: const EdgeInsets.only(
                                right: 10, top: 10, bottom: 10),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  // 소리듣기로 전환
                                  if (isInput == true) {
                                    isInput = false;
                                    context
                                        .read<VoiceModule>()
                                        .startListening();
                                    setState(() {});
                                  }
                                  // 입력하기로 전환
                                  else {
                                    isInput = true;
                                    context.read<VoiceModule>().stopListening();
                                    setState(() {});
                                  }
                                });
                              },
                              style: TextButton.styleFrom(
                                primary: darkMode ? kWhite : kBlack,
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                side: BorderSide(
                                    color: darkMode ? kWhite : kBlack,
                                    width: 2),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                isInput ? '소리 듣기' : '입력하기',
                                style: TextStyle(
                                  color: darkMode ? kWhite : kBlack,
                                  fontSize: kS,
                                  fontFamily: 'PretendardBold',
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                                right: 10, top: 10, bottom: 10),
                            child: TextButton(
                              onPressed: () {
                                context.read<VoiceModule>().stopListening();
                                showCupertinoModalPopup(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      chatModalBuilder(context,
                                          screenshotController:
                                              screenshotController),
                                ).then(
                                  (value) {
                                    setState(() {});
                                  },
                                );
                              },
                              style: TextButton.styleFrom(
                                primary: darkMode ? kBlack : kWhite,
                                backgroundColor: darkMode ? kWhite : kBlack,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                '종료',
                                style: TextStyle(
                                  color: darkMode ? kBlack : kWhite,
                                  fontSize: kS,
                                  fontFamily: 'PretendardBold',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              // tail
              isEmpty
                  ? Positioned(
                      bottom: 80,
                      width: screenWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          voiceModeSelect(
                            kGrey5,
                            const BorderRadius.only(
                                topRight: Radius.circular(150)),
                            [0.0, 15.0],
                            Icons.mic_rounded,
                            '소리 듣기',
                            () {
                              setState(() {
                                isInput = false;
                                isEmpty = false;
                                context.read<VoiceModule>().startListening();
                              });
                            },
                          ),
                          voiceModeSelect(
                            kMain,
                            const BorderRadius.only(
                                topLeft: Radius.circular(150)),
                            [15.0, 0.0],
                            Icons.keyboard_rounded,
                            '입력하기',
                            () {
                              setState(() {
                                isInput = true;
                                isEmpty = false;
                                context.read<VoiceModule>().stopListening();
                              });
                            },
                            isRight: true,
                          ),
                        ],
                      ),
                    )
                  : isInput
                      // 텍스트 필드
                      ? Positioned(
                          bottom: isOpen ? 0 : 80,
                          width: screenWidth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            child: Focus(
                              onFocusChange: (focused) {
                                setState(() {
                                  isOpen = focused ? true : false;
                                });
                              },
                              child: Row(
                                children: [
                                  Flexible(
                                    child: TextField(
                                      controller: textController,
                                      onSubmitted: _handleSubmitted,
                                      onChanged: (value) {},
                                      style: TextStyle(
                                          fontSize: kS,
                                          color: darkMode ? kWhite : kBlack),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: darkMode ? kBlack : kGrey1,
                                        hintText: "입력하세요",
                                        hintStyle: TextStyle(
                                            fontSize: kS, color: kGrey5),
                                        counterText: "",
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 15),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color:
                                                  darkMode ? kWhite : kBlack),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: kGrey5),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: IconButton(
                                      icon: Icon(Icons.send, color: kMain),
                                      onPressed: () =>
                                          _handleSubmitted(textController.text),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      // 소리 듣기 표시
                      : Positioned(
                          bottom: 80,
                          height: 80,
                          width: screenWidth,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: darkMode
                                        ? kBlack.withOpacity(0.6)
                                        : kGrey1.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child:
                                      LoadingAnimationWidget.staggeredDotsWave(
                                    color: darkMode ? kWhite : kBlack,
                                    size: 30.0,
                                  ),
                                ),
                                Text(
                                  '대화를 듣고 있습니다',
                                  style: TextStyle(
                                    color: darkMode ? kWhite : kBlack,
                                    fontSize: kXS,
                                  ),
                                ),
                              ]),
                        )
            ],
          ),
        ),
      );
    });
  }
}

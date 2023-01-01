import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hear_for_you/widgets/chat_modal.dart';
import 'package:hear_for_you/widgets/voice_mode_select.dart';
import 'package:screenshot/screenshot.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:toast/toast.dart';

import '../constants.dart';
import '../service/permission_check.dart';

class VoiceModule extends StatefulWidget {
  const VoiceModule({Key? key}) : super(key: key);

  @override
  State<VoiceModule> createState() => _VoiceModuleState();
}

class _VoiceModuleState extends State<VoiceModule> {
  bool regularFlag = false;
  late bool isInput;
  bool isOpen = false;

  final TextEditingController textController = TextEditingController();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  initState() {
    super.initState();
    PermissionCheckClass.requestRecognitionPermission(context);

    isEmpty = false;
    isInput = true;
    _initSpeech();
  }

  //////////////////////////////////// STT ////////////////////////////////////
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  String _currentWords = '';

  // This has to happen only once per app
  void _initSpeech() async {
    await _speechToText.initialize(
        onError: errorListener, onStatus: statusListener);
  }

  // 에러 종류에 따라 팝업 띄우기
  // error_speech_timeout, error_busy, error_network, error_
  void errorListener(SpeechRecognitionError error) {
    Toast.show(error.errorMsg, duration: Toast.lengthLong, gravity: Toast.top);
    setState(() {
      isInput = true;
      _isListening = false;
    });
  }

  // stt가 특정시간이 지나면 자동종료가 되기때문에 다시 시작해주는 코드 필요
  void statusListener(String status) async {
    debugPrint('onStatus: $status / _isListening $_isListening');

    // 갱신하고 다시 재인식
    if (status == "done" && _isListening) {
      setState(() {
        _lastWords += " $_currentWords";
        if (_lastWords.isNotEmpty && _lastWords != " ") {
          voiceScreenChat.insert(0, [_lastWords, false]);
        }
        _lastWords = "";
        _currentWords = "";
      });
      await _startListening();
    }
    // if (status == "notListening" && !_isListening) {
    //   await _stopListening();
    // }
  }

  /// Each time to start a speech recognition session
  Future _startListening() async {
    // await _stopListening();
    setState(() {
      if (regularValue) {
        regularFlag = true;
        regularValue = false;
      }
      _isListening = true;
    });
    await Future.delayed(const Duration(milliseconds: 1));
    await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          setState(() {
            _currentWords = " ${result.recognizedWords}";
          });
        },
        localeId: 'ko_KR',
        partialResults: false,
        listenMode: ListenMode.confirmation);
  }

  Future _stopListening() async {
    if (_isListening) {
      _isListening = false;
    }
    await _speechToText.stop();
    setState(() {
      // 이전에 regularValue가 true였다면 다시켜기
      // 아니라면 켜지면 안됌
      if (regularFlag) {
        regularValue = true;
        regularFlag = false;
      }
    });
  }

  ////////////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
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

    // 소리를 듣고 있다는 표시
    Widget waveForm(height) {
      return Container(
        width: 6,
        height: height,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: darkMode ? kWhite : const Color(0xFF434343),
        ),
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

    ToastContext().init(context);

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
                      SizedBox(width: screenWidth, height: 20),
                      Flexible(
                          child: SingleChildScrollView(
                        reverse: true,
                        child: Screenshot(
                          controller: screenshotController,
                          child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              reverse: true,
                              itemCount: voiceScreenChat.length,
                              itemBuilder: (BuildContext context, idx) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  margin: EdgeInsets.only(
                                      bottom: (idx + 1 <
                                                  voiceScreenChat.length) &&
                                              (voiceScreenChat[idx][1] !=
                                                  voiceScreenChat[idx + 1][1])
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
                                  _startListening();
                                }
                                // 입력하기로 전환
                                else {
                                  isInput = true;
                                  _stopListening();
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
                                  color: darkMode ? kWhite : kBlack, width: 2),
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
                              showCupertinoModalPopup(
                                context: context,
                                builder: (BuildContext context) =>
                                    chatModalBuilder(
                                        context,
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
                              '저장',
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
                              _startListening();
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
                                            color: darkMode ? kWhite : kBlack),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: kGrey5),
                                        borderRadius: BorderRadius.circular(15),
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
                                color: darkMode
                                    ? kBlack.withOpacity(0.65)
                                    : kWhite.withOpacity(0.85),
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: darkMode
                                      ? kWhite
                                      : const Color(0xFF434343),
                                  size: 30.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '대화를 듣고 있습니다',
                                style: TextStyle(
                                  color: darkMode
                                      ? kWhite
                                      : const Color(0xFF434343),
                                  fontSize: kXS,
                                ),
                              ),
                            ]),
                        // Container(
                        //   padding: EdgeInsets.symmetric(
                        //       horizontal: screenWidth * 0.3),
                        //   decoration: BoxDecoration(
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: darkMode
                        //             ? kBlack.withOpacity(0.65)
                        //             : kWhite.withOpacity(0.85),
                        //         blurRadius: 20,
                        //       ),
                        //     ],
                        //     shape: BoxShape.circle,
                        //   ),
                        //   child: Column(
                        //     children: [
                        //       const SizedBox(height: 10),
                        //       SizedBox(
                        //         height: 40,
                        //         child: Row(
                        //           mainAxisAlignment: MainAxisAlignment.center,
                        //           children: [
                        //            waveForm(6.0),
                        //             waveForm(6.0),
                        //             waveForm(6.0),
                        //             waveForm(6.0),
                        //             waveForm(6.0),
                        //           ],
                        //         ),
                        //       ),
                        //       Container(
                        //         padding: EdgeInsets.symmetric(horizontal: 10),
                        //         child: _lastWords.isNotEmpty
                        //             ? bubble(
                        //                 '$_lastWords $_currentWords', false)
                        //             : Text('lastWords is empty'),
                        //       ),

                        //       // Text(
                        //       //   '_isListening $_isListening',
                        //       //   style: TextStyle(
                        //       //     color: darkMode
                        //       //         ? kWhite
                        //       //         : const Color(0xFF434343),
                        //       //     fontSize: kXS,
                        //       //   ),
                        //       // ),
                        //     ],
                        //   ),
                        // ),
                      ),
          ],
        ),
      ),
    );
  }
}

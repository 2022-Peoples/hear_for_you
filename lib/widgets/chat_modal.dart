import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hear_for_you/widgets/custom_dialog.dart';
import 'package:image_gallery_saver_v3/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';

import '../constants.dart';

_saveAsImage(String fileName, screenshotController) {
  screenshotController.capture().then((image) async {
    final result =
        await ImageGallerySaver.saveImage(image, name: '$fileName-chat');
    debugPrint(result);
  });
}

/// storage/emulated/0/Android/data/com.example.hear_for_you/files/2022-12-17T12:41:41.844957.txt
_saveAsText(String fileName) async {
  String reChatList = "";
  for (int i = 0; i < voiceScreenChat.length; i++) {
    if (voiceScreenChat[i][1] == true) {
      reChatList += '[나] ${voiceScreenChat[i][0]}\n';
    } else {
      reChatList += '[상대방] ${voiceScreenChat[i][0]}\n';
    }
  }
  debugPrint(reChatList.toString());
  Clipboard.setData(ClipboardData(text: reChatList.toString()));
}

_endChat() {
  voiceScreenChat = [];
  isEmpty = true;
}

// 음성모드 저장시 뜨는 모달
CupertinoActionSheet chatModalBuilder(BuildContext context,
    {screenshotController = ScreenshotController}) {
  final fileName = DateTime.now().toIso8601String();
  final navigator = Navigator.of(context);

  return CupertinoActionSheet(
    actions: [
      // 전체 대화 이미지로 저장
      CupertinoActionSheetAction(
        child: Text('이미지로 저장하기', style: TextStyle(color: kGrey4)),
        onPressed: () async {
          _saveAsImage(fileName, screenshotController);

          final confirmed = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return oneButtonDialog(
                  context,
                  "이미지 저장",
                  "대화 내용을 갤러리에 저장하였습니다!",
                  "확인",
                  () {
                    Navigator.pop(context, true);
                  },
                );
              });

          if (confirmed) {
            _endChat();
            navigator.pop();
          }

          // 음성모드 초기화면으로 가기
        },
      ),
      // 전체 대화 텍스트 파일로 저장
      CupertinoActionSheetAction(
        onPressed: () async {
          _saveAsText(fileName);

          final confirmed = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return oneButtonDialog(
                  context,
                  "클립보드에 복사",
                  "대화 내용을 클립보드에 복사하였습니다!",
                  "확인",
                  () {
                    Navigator.pop(context, true);
                  },
                );
              });

          if (confirmed) {
            _endChat();
            navigator.pop();
          }
        },
        child: Text('클립보드에 복사하기', style: TextStyle(color: kGrey4)),
      ),
      // 종료하고 대화 초기화하기
      CupertinoActionSheetAction(
        child: const Text(
          '종료하기',
          style: TextStyle(color: Colors.red),
        ),
        onPressed: () {
          _endChat();
          navigator.pop();
        },
      ),
    ],
    cancelButton: CupertinoActionSheetAction(
      child: Text('취소', style: TextStyle(color: kMain)),
      onPressed: () {
        navigator.pop();
      },
    ),
  );
}

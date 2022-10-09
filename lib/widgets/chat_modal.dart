import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

CupertinoActionSheet chatModalBuilder(BuildContext context) {
  return CupertinoActionSheet(
    actions: [
      CupertinoActionSheetAction(
        child: const Text('이미지로 저장하기'),
        onPressed: () {},
      ),
      CupertinoActionSheetAction(
        child: const Text('텍스트 파일로 저장하기'),
        onPressed: () {},
      ),
      CupertinoActionSheetAction(
        child: const Text(
          '종료하기',
          style: TextStyle(color: Colors.red),
        ),
        onPressed: () {},
      ),
    ],
    cancelButton: CupertinoActionSheetAction(
      child: Text('취소', style: TextStyle(color: kMain)),
      onPressed: () {
        Navigator.pop(context);
      },
    ),
  );
}

import 'dart:async';
import 'Functions.dart';
import 'package:flutter/material.dart';

class SoundPage extends StatefulWidget {
  const SoundPage({Key? key}) : super(key: key);

  @override
  State<SoundPage> createState() => SoundPageState();
}

class SoundPageState extends State<SoundPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("테스트 페이지입니다.\n하단의 버튼을 누르면 서버와 데이터를 주고받습니다.",
            style: TextStyle(
              fontSize: 25,
            )),
        IconButton(
            icon: const Icon(Icons.dark_mode),
            iconSize: 50,
            onPressed: () {
              showDialog(
                  context: context,
                  barrierDismissible: true, // 창 바깥쪽을 클릭하면 사라짐
                  builder: (BuildContext context) {
                    return const ModelPopup();
                  });
            })
      ],
    );
  }
}

class ModelPopup extends StatefulWidget {
  const ModelPopup({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PopupState();
}

class PopupState extends State<ModelPopup> {
  Widget object = loadingWidget();
  @override
  initState() {
    super.initState();
    Future<String> prediction = FunctionClass.getPrediction();
    prediction.then((val) {
      setState(() {
        object = resultWidget(val);
      });
    }).catchError((error) {
      // SignalException은 무슨 소리인지 인지하지 못했을 경우임. 이때는 에러는 아니므로 다른 처리
      if (error.toString() == "SignalException") {
        setState(() {
          object = resultWidget("알 수 없는 소리입니다");
        });
      } else {
        setState(() {
          object = errorWidget(error.toString());
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        content: SizedBox(width: 200, height: 100, child: object));
  }
}

// 로딩중일 때 띄울 위젯
Widget loadingWidget() {
  return const Center(child: Text("분석중입니다"));
}

// 분석이 완료되고 띄울 위젯
Widget resultWidget(String result) {
  return Column(children: [
    const Text("분석 결과"),
    Text(result),
  ]);
}

// 분석 실패 혹은 에러 발생 시 띄울 위젯
Widget errorWidget(String result) {
  return Column(
    children: [
      const Text("오류 발생"),
      Text(result),
    ],
  );
}

import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:hear_for_you/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import '../service/functions.dart';

class RecordModule extends ChangeNotifier {
  var _context;
  var _recordTimer;
  var _currentWords;
  bool isRecording = false;
  var beforeDb = -1.0;
  var theSource = AudioSource.microphone;

  String _mPath = '';
  FlutterSoundRecorder? mRecorder = FlutterSoundRecorder(logLevel: Level.error);
  late StreamSubscription<RecordingDisposition> _recorderSubscription;

  Future<void> initState() async {
    debugPrint('debugging : 상시모드 init');
    var dir;

    isInit = false;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    _mPath = "${dir?.path}/audio.wav";
    openTheRecorder().then((value) {
      mRecorder!.setSubscriptionDuration(const Duration(seconds: 1));
      notifyListeners();
    });
  }

  Future<void> disposeState() async {
    debugPrint('debugging : 상시모드 off');
    await stop();
    await mRecorder!.closeRecorder();
    notifyListeners();
  }

  Future<void> openTheRecorder() async {
    var status = await Permission.microphone.isGranted;
    if (!status) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await mRecorder!.openRecorder();
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void onData(RecordingDisposition event) async {
    double? decibel = event.decibels;
    debugPrint('debugging : decibel $decibel');
    if (decibel == beforeDb) {
      debugPrint('debugging : 동일 데시벨 $beforeDb');
      return;
    } else if (decibel! >= dB) {
      beforeDb = decibel;
      debugPrint('debugging : over $dB dB');
      debugPrint('debugging : 저장 경로 $_mPath');

      await stop();
      FunctionClass.showModelProcess(_context);
    }
  }

  // ----------------------  Here is the code for recording and playback -------

  Future<void> record() async {
    var isRepeating = false;
    debugPrint('debugging : 상시모드 on');
    isRecording = true;
    _recordTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      debugPrint('debugging : recordTimer ${DateTime.now().second}');
      // 녹음 시작
      if (isRepeating) {
        mRecorder!.stopRecorder();
      }
      await mRecorder!.startRecorder(toFile: _mPath).then((value) async {
        notifyListeners();
        try {
          _recorderSubscription = mRecorder!.onProgress!.listen(onData);
          notifyListeners();
        } catch (err) {
          debugPrint('debugging : _recorderSubscription $err');
        }
        notifyListeners();
      });
      isRepeating = true;

      // Timer(const Duration(seconds: 5), handleTimeout);
    });
  }

  // void handleTimeout() async {
  //   stop();
  // }

  Future<void> stop() async {
    debugPrint('debugging : stop recording');
    isRecording = false;
    Timer(const Duration(milliseconds: 500), () {});
    await mRecorder!.stopRecorder().then((value) {
      _recorderSubscription.cancel();
      _recordTimer?.cancel();
      notifyListeners();
    });
  }
}

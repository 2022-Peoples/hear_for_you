import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:hear_for_you/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:toast/toast.dart';

import '../service/functions.dart';

class RecordModule extends ChangeNotifier {
  var _context;
  var _recordTimer;
  var _currentWords;
  bool isRecording = false;
  var theSource = AudioSource.microphone;

  String _mPath = '';
  FlutterSoundRecorder? mRecorder = FlutterSoundRecorder();
  bool _mRecorderIsInited = false;
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
      _mRecorderIsInited = true;
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
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
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
    _mRecorderIsInited = true;
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void onData(RecordingDisposition event) async {
    double? decibel = event.decibels;
    debugPrint('debugging : decibel $decibel');
    if (decibel! >= dB) {
      debugPrint('debugging : over $dB dB');
      debugPrint('debugging : 저장 경로 $_mPath');

      await stop();
      FunctionClass.showPopup(_context);
    }
  }

  // ----------------------  Here is the code for recording and playback -------

  Future<void> record() async {
    debugPrint('debugging : 상시모드 on');
    isRecording = true;
    _recordTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      debugPrint('debugging : recordTimer ${DateTime.now().second}');
      // 녹음 시작
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
    });
  }

  Future<void> stop() async {
    debugPrint('debugging : stop recording');
    isRecording = false;
    const Duration(milliseconds: 500);
    await mRecorder!.stopRecorder().then((value) {
      _recordTimer?.cancel();
      _recorderSubscription.cancel();
      notifyListeners();
    });
  }
}

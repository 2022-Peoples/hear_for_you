import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class nRegualrModule extends ChangeNotifier {
  int recordDuration = 0;
  Timer? timer;
  final audioRecorder = Record();
  StreamSubscription<RecordState>? recordSub;
  RecordState recordState = RecordState.stop;
  StreamSubscription<Amplitude>? amplitudeSub;
  Amplitude? amplitude;

  void _startTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      recordDuration++;
      notifyListeners();
    });
  }

  void disposeState() {
    timer?.cancel();
    recordSub?.cancel();
    amplitudeSub?.cancel();
    audioRecorder.dispose();
    super.dispose();
  }

  void initState() {
    recordSub = audioRecorder.onStateChanged().listen((recordState) {
      recordState = recordState;
      notifyListeners();
    });

    amplitudeSub = audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) {
      amplitude = amp;
      notifyListeners();
    });
  }

  Future<void> start() async {
    try {
      if (await audioRecorder.hasPermission()) {
        // We don't do anything with this but printing
        final isSupported = await audioRecorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );
        if (kDebugMode) {
          print('${AudioEncoder.aacLc.name} supported: $isSupported');
        }

        // final devs = await _audioRecorder.listInputDevices();
        // final isRecording = await _audioRecorder.isRecording();

        await audioRecorder.start();
        recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> stop() async {
    timer?.cancel();
    recordDuration = 0;

    final path = await audioRecorder.stop();

    if (path != null) {
      // widget.onStop(path);
    }
  }

  Future<void> pause() async {
    timer?.cancel();
    await audioRecorder.pause();
  }

  Future<void> resume() async {
    _startTimer();
    await audioRecorder.resume();
  }
}

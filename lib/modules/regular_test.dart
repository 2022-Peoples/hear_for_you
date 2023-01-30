import 'package:flutter/material.dart';
import 'package:hear_for_you/modules/audio_player.dart';
import 'package:hear_for_you/modules/new_regular_module.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => nRegualrModule(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showPlayer = false;
  String? audioPath;

  @override
  void initState() {
    showPlayer = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: showPlayer
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: AudioPlayer(
                    source: audioPath!,
                    onDelete: () {
                      setState(() => showPlayer = false);
                    },
                  ),
                )
              : AudioRecorder(
                  onStop: (path) {
                    print('Recorded file path: $path');
                    setState(() {
                      audioPath = path;
                      showPlayer = true;
                    });
                  },
                ),
        ),
      ),
    );
  }
}

class AudioRecorder extends StatefulWidget {
  final void Function(String path) onStop;

  const AudioRecorder({Key? key, required this.onStop}) : super(key: key);

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  var audioRecorder,
      recordSub,
      recordState,
      recordDuration,
      amplitude,
      amplitudeSub;

  @override
  void initState() {
    audioRecorder = context.read<nRegualrModule>().audioRecorder;
    recordSub = context.read<nRegualrModule>().recordSub;
    recordState = context.read<nRegualrModule>().recordState;
    recordDuration = context.read<nRegualrModule>().recordDuration;
    amplitude = context.read<nRegualrModule>().amplitude;
    amplitudeSub = context.read<nRegualrModule>().amplitudeSub;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildRecordStopControl(),
                const SizedBox(width: 20),
                _buildPauseResumeControl(),
                const SizedBox(width: 20),
                _buildText(),
              ],
            ),
            if (amplitude != null) ...[
              const SizedBox(height: 40),
              Text('Current: ${amplitude?.current ?? 0.0}'),
              Text('Max: $amplitude?.max ?? 0.0}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (recordState != RecordState.stop)
                ? context.read<nRegualrModule>().stop()
                : context.read<nRegualrModule>().start();
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    if (recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (recordState == RecordState.pause)
                ? context.read<nRegualrModule>().resume()
                : context.read<nRegualrModule>().pause();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (recordState != RecordState.stop) {
      return _buildTimer();
    }

    return const Text("Waiting to record");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(recordDuration ~/ 60);
    final String seconds = _formatNumber(recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }
}

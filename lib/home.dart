import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum AudioState {
  isPlaying,
  isPaused,
  isStopped,
  isRecording,
  isRecordingPaused,
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterSoundRecorder _recorder = new FlutterSoundRecorder();
  FlutterSoundPlayer _player = new FlutterSoundPlayer();
  Codec _codec = Codec.aacADTS;
  double _duration = 0;
  AudioState _state = AudioState.isStopped;
  String _path;
  bool _recorderIsInited = false;
  bool _playerIsInited = false;

  Future<void> record() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    var tempDir = await getTemporaryDirectory();
    _path = '${tempDir.path}/flutter_sound.aac';
    await _recorder.startRecorder(toFile: _path, codec: _codec).then((value) {
      setState(() {
        _state = AudioState.isRecording;
      });
    });
  }

  Future<void> stopRecorder() async {
    await _recorder.stopRecorder().then((value) {
      setState(() {
        _state = AudioState.isRecordingPaused;
      });
    });
  }

  Future<void> getDuration() async {
    try {
      var path = _path[_codec.index];
      var d = path != null ? await flutterSoundHelper.duration(path) : null;
      _duration = d != null ? d.inMilliseconds / 1000.0 : null;
    } on Exception catch (e) {
      print('getDuration error: $e');
    }
    setState(() {});
  }

  void play() async {
    await _player
        .startPlayer(
            fromURI: _path,
            codec: _codec,
            whenFinished: () {
              setState(() {});
            })
        .then((value) {
      setState(() {});
    });
  }

  Future<void> stopPlayer() async {
    if (_player != null) {
      try {
        await _player.stopPlayer().then((value) {
          setState(() {
            _state = AudioState.isStopped;
          });
        });
        await getDuration();
      } on Exception catch (e) {
        print('stopRecorder error: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _recorder.openAudioSession().then((value) {
      setState(() {
        _recorderIsInited = true;
      });
    });
    _player.openAudioSession().then((value) {
      setState(() {
        _playerIsInited = true;
      });
    });
  }

  @override
  void dispose() {
    _recorder.closeAudioSession();
    _recorder = null;
    _player.closeAudioSession();
    _player = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              TextButton.icon(
                  onPressed: () => record(),
                  icon: Icon(Icons.mic),
                  label: Text('Başla')),
              TextButton.icon(
                  onPressed: () => stopRecorder(),
                  icon: Icon(Icons.stop),
                  label: Text('Durdur')),
            ],
          ),
          Text(_duration.toStringAsFixed(2)),
          Row(
            children: [
              TextButton.icon(
                  onPressed: () => play(),
                  icon: Icon(Icons.play_arrow),
                  label: Text('Oynat')),
              TextButton.icon(
                  onPressed: () => stopPlayer(),
                  icon: Icon(Icons.stop),
                  label: Text('Durdur')),
            ],
          ),
        ],
      ),
    );
  }
}

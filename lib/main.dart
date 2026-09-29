import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const RadioApp());
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KVCR Radio Stream',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const StreamPlayerScreen(),
    );
  }
}

class StreamPlayerScreen extends StatefulWidget {
  const StreamPlayerScreen({super.key});

  @override
  State<StreamPlayerScreen> createState() => _StreamPlayerScreenState();
}

class _StreamPlayerScreenState extends State<StreamPlayerScreen> {
  static const String _streamUrl =
      '[https://kvcr.streamguys1.com/live?dist=nprweb](https://kvcr.streamguys1.com/live?dist=nprweb)';
  late final AudioPlayer _player;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _player.setUrl(_streamUrl);
      setState(() => _isInit = true);
    } catch (e) {
      debugPrint('Error loading live stream: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KVCR Live'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radio, size: 100, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              'KVCR 91.9 FM',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'NPR News & Music',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing ?? false;

                // Show spinner while connecting or buffering
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return const SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(),
                  );
                }

                // Play / Pause toggle button
                return IconButton.filled(
                  iconSize: 56,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (playing) {
                      _player.pause();
                    } else {
                      // If it disconnected or wasn't set, reload before playing
                      if (!_isInit) {
                        _initAudio().then((_) => _player.play());
                      } else {
                        _player.play();
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

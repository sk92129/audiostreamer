// Kang Engineering Systems LLC, 2026, Copyright protection

import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.kangengineering.audiostreamer.audio',
    androidNotificationChannelName: 'KVCR playback',
    androidNotificationChannelDescription:
        'Shows the live station and playback controls.',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/ic_stat_radio',
  );
  runApp(const RadioApp());
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KAS',
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
      'https://kvcr.streamguys1.com/live?dist=nprweb';
  static const String _launcherIconAsset = 'assets/images/app_icon.png';
  late final AudioPlayer _player;
  bool _isInit = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<Uri> _launcherIconUri() async {
    final data = await rootBundle.load(_launcherIconAsset);
    final directory = await getApplicationCacheDirectory();
    final file = File('${directory.path}/kas_launcher_icon.png');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return file.uri;
  }

  Future<void> _initAudio() async {
    try {
      // Route through the media stream so device volume (including max)
      // controls the speaker, instead of the quiet call/earpiece path.
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _player.setVolume(1.0);
      final iconArtUri = await _launcherIconUri();
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(_streamUrl),
          headers: const {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
          tag: MediaItem(
            id: _streamUrl,
            title: 'KVCR 91.9 FM',
            artist: 'NPR News & Music',
            album: 'KVCR Live',
            artUri: iconArtUri,
            isLive: true,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _isInit = true;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error loading live stream: $e');
      if (!mounted) return;
      setState(() {
        _isInit = false;
        _error = 'Could not start the live stream';
      });
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
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
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
                        _initAudio().then((_) {
                          if (_isInit) _player.play();
                        });
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

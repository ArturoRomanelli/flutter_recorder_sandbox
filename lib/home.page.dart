import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_recorder_sandbox/audio_chat.controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = useMemoized(() => AudioRecorder());
    useEffect(() => record.dispose, []);

    final recordingPath = useState<String?>(null);
    final isRecording = useState<bool>(false);
    final permission = useState<bool>(false);

    final list = ref.watch(audioChatListControllerProvider);

    Future<bool> getPermission() async {
      final hasPermission = await record.hasPermission();
      return hasPermission;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: list.isEmpty
          ? Center(
              child: Text(
              'No records',
              style: Theme.of(context).textTheme.headlineMedium,
            ))
          : ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemCount: list.length,
              itemBuilder: (context, index) =>
                  ChatBubble(audioPath: list[index]),
            ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: isRecording.value
            ? () async {
                final path = await record.stop();
                isRecording.value = false;

                if (path == null) {
                  throw Exception('Path is null - what happened?');
                }

                recordingPath.value = path;
                ref.read(audioChatListControllerProvider.notifier).add(path);
              }
            : () async {
                if (!permission.value) {
                  permission.value = await getPermission();
                }
                final appDirectory = await getApplicationDocumentsDirectory();
                final path = '${appDirectory.path}/audio${list.length}.m4a';
                await record.start(const RecordConfig(), path: path);
                isRecording.value = true;
                recordingPath.value = null;
              },
        child: Icon(isRecording.value ? Icons.stop : Icons.mic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ChatBubble extends HookWidget {
  const ChatBubble({super.key, required this.audioPath});

  final String audioPath;
  @override
  Widget build(BuildContext context) {
    final player = useMemoized(() => AudioPlayer());
    useEffect(() => player.dispose, []);

    final isPlaying = useState<bool>(false);

    final position = useStream<Duration>(player.onPositionChanged);
    final duration = useState<Duration?>(null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
          decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.green),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: isPlaying.value
                    ? () async {
                        await player.pause();
                        isPlaying.value = false;
                      }
                    : () async {
                        duration.value = await player.getDuration();
                        await player.play(DeviceFileSource(audioPath));
                        isPlaying.value = true;
                      },
                icon: isPlaying.value
                    ? const Icon(Icons.pause)
                    : const Icon(Icons.play_arrow),
              ),
              Slider(
                  onChanged: (value) async {
                    final dur = await player.getDuration();
                    if (dur == null) {
                      return;
                    }
                    // duration.value = dur;
                    final position = value * dur.inMilliseconds;

                    player.seek(Duration(milliseconds: position.round()));
                  },
                  value: switch ((position.data, duration.value)) {
                    (_, Duration.zero) => 0.0,
                    (Duration position, Duration duration) =>
                      position.inMilliseconds / duration.inMilliseconds,
                    _ => 0.0,
                  }),
            ],
          )),
    );
  }
}
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   Widget build(BuildContext context) {
//     final record = AudioRecorder();

//     bool isRecording = false;
//     String? recordingPath;

//     return Scaffold(
//       body: Center(child: Text(recordingPath ?? 'No records')),
//       floatingActionButton: FloatingActionButton.large(
//         onPressed: () async {
//           if (isRecording) {
//             final path = await record.stop();

//             if (path != null) {
//               setState(() {
//                 isRecording = false;
//                 recordingPath = path;
//               });
//             }
//           } else {
//             if (await record.hasPermission()) {
//               final appDirectory = await getApplicationDocumentsDirectory();
//               final path = '${appDirectory.path}/audio.m4a';
//               await record.start(const RecordConfig(), path: path);
//               setState(() {
//                 isRecording = true;
//                 recordingPath = null;
//               });
//             }
//           }
//         },
//         child: Icon(isRecording ? Icons.stop : Icons.mic),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }
// }

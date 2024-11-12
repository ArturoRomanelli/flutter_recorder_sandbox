import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class MyHomePage extends HookWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final record = useMemoized(() => AudioRecorder());
    useEffect(() => record.dispose, []);

    final recordingPath = useState<String?>(null);
    final isRecording = useState<bool>(false);
    final permission = useState<bool>(false);

    Future<bool> getPermission() async {
      final hasPermission = await record.hasPermission();
      return hasPermission;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              recordingPath.value ?? 'No records',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
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
              }
            : () async {
                if (!permission.value) {
                  permission.value = await getPermission();
                }
                final appDirectory = await getApplicationDocumentsDirectory();
                final path = '${appDirectory.path}/audio.m4a';
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

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_chat.controller.g.dart';

@riverpod
class AudioChatListController extends _$AudioChatListController {
  @override
  List<String> build() {
    return [];
  }

  void add(String audioPath) {
    state = [...state, audioPath];
  }
}

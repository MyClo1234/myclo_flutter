import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/modules/chat_api.dart';
import 'auth_provider.dart';
import 'recommendation_provider.dart';
import 'weather_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isImage;
  final String? imageUrl;
  final Map<String, dynamic>? recommendation;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isImage = false,
    this.imageUrl,
    this.recommendation,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isPickUpdated;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isPickUpdated = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isPickUpdated,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isPickUpdated: isPickUpdated ?? this.isPickUpdated,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatApi _api;
  final Ref _ref;

  ChatNotifier(this._api, this._ref)
    : super(
        ChatState(
          messages: [
            ChatMessage(
              text: "안녕하세요! 오늘 어떤 스타일을 찾으시나요? 제가 완벽한 코디를 도와드릴게요.",
              isUser: false,
            ),
          ],
        ),
      );

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: text, isUser: true),
      ],
      isLoading: true,
      isPickUpdated: false, // Reset flag
    );

    try {
      final authState = _ref.read(authProvider);
      final weatherState = _ref.read(weatherProvider);

      final userId = authState.id;
      final lat = weatherState.value?.lat;
      final lon = weatherState.value?.lon;

      final response = await _api.sendMessage(text, userId, lat: lat, lon: lon);

      final botResponse = response['response'] as String? ?? 'No response';
      final isPickUpdated = response['is_pick_updated'] as bool? ?? false;

      List<ChatMessage> newMessages = [];

      // Text response
      newMessages.add(ChatMessage(text: botResponse, isUser: false));

      state = state.copyWith(
        messages: [...state.messages, ...newMessages],
        isLoading: false,
        isPickUpdated: isPickUpdated,
      );

      // Trigger global recommendation refresh if pick was updated
      if (isPickUpdated) {
        _ref.read(recommendationProvider.notifier).refresh();
      }
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: "Error: $e", isUser: false),
        ],
        isLoading: false,
      );
    }
  }

  void resetPickUpdated() {
    state = state.copyWith(isPickUpdated: false);
  }

  void clearChat() {
    state = ChatState(
      messages: [
        ChatMessage(
          text: "안녕하세요! 오늘 어떤 스타일을 찾으시나요? 제가 완벽한 코디를 도와드릴게요.",
          isUser: false,
        ),
      ],
    );
  }
}

final chatApiProvider = Provider((ref) => ChatApi());

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final api = ref.watch(chatApiProvider);
  return ChatNotifier(api, ref);
});

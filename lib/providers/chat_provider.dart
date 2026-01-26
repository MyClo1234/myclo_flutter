import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/modules/chat_api.dart';
import 'auth_provider.dart';

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

  ChatNotifier(this._api, this._ref) : super(ChatState());

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
      final userId = authState.id;

      final response = await _api.sendMessage(text, userId);

      final botResponse = response['response'] as String? ?? 'No response';
      final isPickUpdated = response['is_pick_updated'] as bool? ?? false;
      // final recommendations = response['recommendations'] as List?;
      final todaysPick = response['todays_pick'] as Map<String, dynamic>?;

      List<ChatMessage> newMessages = [];

      // Text response
      newMessages.add(ChatMessage(text: botResponse, isUser: false));

      // Image (Today's Pick) response
      if (todaysPick != null && todaysPick['image_url'] != null) {
        newMessages.add(
          ChatMessage(
            text: "Here is your Today's Pick!",
            isUser: false,
            isImage: true,
            imageUrl: todaysPick['image_url'],
            recommendation: todaysPick,
          ),
        );
      }

      state = state.copyWith(
        messages: [...state.messages, ...newMessages],
        isLoading: false,
        isPickUpdated: isPickUpdated,
      );
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
}

final chatApiProvider = Provider((ref) => ChatApi());

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final api = ref.watch(chatApiProvider);
  return ChatNotifier(api, ref);
});

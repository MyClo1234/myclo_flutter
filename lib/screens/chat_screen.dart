import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Trigger handling (Snack bar when pick updated)
    ref.listen(chatProvider, (prev, next) {
      if (next.isPickUpdated && !(prev?.isPickUpdated ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Today's Pick has been updated!"),
            backgroundColor: AppTheme.primary,
            action: SnackBarAction(
              label: 'Check',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to Home or Refresh
                // For now, handled by main wrapper or user manual navigation
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nano Banana Chat"),
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTheme.headingMedium,
      ),
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  chatState.messages.length + (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length && chatState.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  );
                }

                final message = chatState.messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child:
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              border: isUser ? null : Border.all(color: AppTheme.border),
              boxShadow: isUser
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              message.text,
              style: isUser
                  ? AppTheme.bodyLarge.copyWith(color: Colors.white)
                  : AppTheme.bodyLarge,
            ),
          ).animate().fade().slideX(
            begin: isUser ? 0.2 : -0.2,
            end: 0,
            duration: 300.ms,
          ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppTheme.bgLight,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            icon: const Icon(LucideIcons.send, size: 20),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import 'wardrobe_new_screen.dart';
import 'outfit_detail_screen.dart';
import '../providers/recommendation_provider.dart';

import '../services/api_service.dart';
import '../utils/responsive_helper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Chat state
  final List<Map<String, dynamic>> _messages = [
    {
      'id': 1,
      'type': 'bot',
      'text': 'Where are we going today? I can help you find the perfect look.',
    },
  ];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    // Initial fetch handled by provider build or can be triggered here
    // ref.read(recommendationProvider.notifier).refresh(); // optional
  }

  void _handleSend() {
    if (_chatController.text.trim().isEmpty) return;

    final text = _chatController.text;
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'type': 'user',
        'text': text,
      });
      _chatController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Mock response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch,
            'type': 'bot',
            'text':
                "I've curated 3 outfits for your date night. Based on your preferences, I focused on a sleek, dark aesthetic.",
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final isWeb = ResponsiveHelper.isWeb(context);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ResponsiveWrapper(
                  maxWidth: 1200,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: isWeb ? _buildWebLayout() : _buildMobileLayout(),
                  ),
                ),
              ),
            ],
          ),
          // FAB
          if (!isWeb)
            Positioned(
              bottom: 30, // Above Navbar
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WardrobeNewScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  child: const Icon(LucideIcons.plus, size: 28),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isWeb
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WardrobeNewScreen()),
                );
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(LucideIcons.plus, size: 28),
            )
          : null,
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildInfoCards().animate().scale(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 32),
        _buildTodaysPick(),
        const SizedBox(height: 32),
        _buildChatSection(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildInfoCards().animate().scale(
                delay: 200.ms,
                duration: 400.ms,
              ),
              const SizedBox(height: 32),
              _buildTodaysPick(),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const SizedBox(height: 100), // Align with header-ish
              _buildChatSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good Morning,',
          style: Theme.of(context).textTheme.headlineMedium,
        ).animate().fadeIn().moveY(begin: 10, end: 0, duration: 400.ms),
        Text(
          'Seonghyeon.',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: AppTheme.primary),
        ).animate().fadeIn().moveY(
          begin: 10,
          end: 0,
          delay: 100.ms,
          duration: 400.ms,
        ),
        const SizedBox(height: 8),
        Text(
          'Ready to conquer the rain today?',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 110,
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(LucideIcons.cloudRain, color: Colors.blueAccent),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '18°C',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rainy intervals',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 110,
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(LucideIcons.calendar, color: AppTheme.accent),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3 Events',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'First: 10:00 AM',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysPick() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Pick',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              onPressed: () {
                ref.read(recommendationProvider.notifier).refresh();
              },

              icon: const Icon(
                LucideIcons.refreshCw,
                size: 16,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 16),

        ref
            .watch(recommendationProvider)
            .when(
              data: (outfit) {
                if (outfit == null) {
                  return const Center(child: Text('No outfit found'));
                }
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OutfitDetailScreen(outfit: outfit),
                      ),
                    );
                  },
                  child: Container(
                    height: 450,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Images
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              Expanded(
                                child: outfit.top.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl:
                                            '${ApiService.baseUrl}${outfit.top.imageUrl}', // Access baseUrl manually or via provider if exposed
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorWidget: (context, url, error) =>
                                            Container(color: AppTheme.bgCard),
                                      )
                                    : Container(
                                        color: AppTheme.bgCard,
                                        child: const Center(
                                          child: Text(
                                            '👔',
                                            style: TextStyle(fontSize: 40),
                                          ),
                                        ),
                                      ),
                              ),
                              Expanded(
                                child: outfit.bottom.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl:
                                            '${ApiService.baseUrl}${outfit.bottom.imageUrl}',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorWidget: (context, url, error) =>
                                            Container(color: AppTheme.bgCard),
                                      )
                                    : Container(
                                        color: AppTheme.bgCard,
                                        child: const Center(
                                          child: Text(
                                            '👖',
                                            style: TextStyle(fontSize: 40),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        // Text Overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black87, Colors.transparent],
                                stops: [0.0, 1.0],
                              ),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(24),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        outfit.styleDescription ??
                                            'Stylish Match',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${outfit.top.color} & ${outfit.bottom.color}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (outfit.reasoning != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          outfit.reasoning!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Match Score',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${(outfit.score * 100).round()}%',
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => Container(
                height: 400,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
              error: (error, stack) => Container(
                height: 400,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(recommendationProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildChatSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Chat with AI', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {
                setState(() => _showHistory = !_showHistory);
              },
              child: Text(
                _showHistory ? 'Chat' : 'History',
                style: const TextStyle(color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['type'] == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 260),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppTheme.primary
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12).copyWith(
                            topRight: isUser ? const Radius.circular(2) : null,
                            topLeft: !isUser ? const Radius.circular(2) : null,
                          ),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: isUser ? Colors.black : Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isTyping)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 40,
                      height: 20,
                      child: Center(
                        child: Text(
                          '...',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                ),
              const Divider(color: AppTheme.borderLight),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Ask for an outfit...',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    onPressed: _handleSend,
                    icon: const Icon(LucideIcons.send, color: AppTheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

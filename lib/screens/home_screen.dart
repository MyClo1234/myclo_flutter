import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import 'outfit_detail_screen.dart';

import '../providers/recommendation_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/auth_provider.dart';

import '../services/api_service.dart';
import '../utils/responsive_helper.dart';
import '../providers/chat_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showStyleOverlay = false;

  @override
  void initState() {
    super.initState();
  }

  void _handleSend() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(text);
    _chatController.clear();
    _scrollToBottom();
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
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ResponsiveWrapper(
                    maxWidth: 1200,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: isWeb ? _buildWebLayout() : _buildMobileLayout(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildTodaysPick(),
        const SizedBox(height: 32),
        _buildInfoCards().animate().scale(delay: 200.ms, duration: 400.ms),
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
              _buildInfoCards().animate().scale(
                delay: 200.ms,
                duration: 400.ms,
              ),
              const SizedBox(height: 24),
              _buildChatSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final authState = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Good Morning, ',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn().moveY(begin: 10, end: 0, duration: 400.ms),
            Text(
              '${authState.username ?? 'User'}.',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AppTheme.primary),
            ).animate().fadeIn().moveY(
              begin: 10,
              end: 0,
              delay: 100.ms,
              duration: 400.ms,
            ),
          ],
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
    final weatherState = ref.watch(weatherProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: weatherState.when(
        data: (state) {
          final weather = state.weather;
          final cityName = state.cityName;

          if (weather == null) {
            return const Center(
              child: Text('No Data', style: TextStyle(color: Colors.white54)),
            );
          }
          final icon = getWeatherIcon(weather.rainType);
          final desc = getWeatherDescription(weather.rainType);
          final tempRange =
              '${weather.minTemp?.round()}° / ${weather.maxTemp?.round()}°';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.blueAccent),
                  if (cityName != null)
                    Text(
                      cityName,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tempRange,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertCircle, color: Colors.red.shade300),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              InkWell(
                onTap: () {
                  ref.read(weatherProvider.notifier).fetchWeather();
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    LucideIcons.refreshCcw,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
              data: (todaysPick) {
                if (todaysPick == null ||
                    (todaysPick.outfit == null &&
                        todaysPick.imageUrl == null)) {
                  return Container(
                    height: 750,
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text('No outfit found for today'),
                    ),
                  );
                }

                // If we have an outfit object, use it. Otherwise, we'll use top-level fields.
                final outfit = todaysPick.outfit;
                final imageUrl = todaysPick.imageUrl;
                final reasoning = todaysPick.reasoning ?? outfit?.reasoning;
                final score = todaysPick.score ?? outfit?.score ?? 0.0;
                final styleDescription =
                    outfit?.styleDescription ?? 'Today\'s Style';

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _showStyleOverlay = !_showStyleOverlay;
                    });
                  },
                  child: Container(
                    height: 750,
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
                          child: (imageUrl != null)
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl.startsWith('http')
                                      ? imageUrl
                                      : '${ApiService.baseUrl}$imageUrl',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: AppTheme.bgCard,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: AppTheme.bgCard,
                                        child: const Icon(
                                          LucideIcons.imageOff,
                                          color: Colors.white24,
                                        ),
                                      ),
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: outfit?.top.imageUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  '${ApiService.baseUrl}${outfit!.top.imageUrl}',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                        color: AppTheme.bgCard,
                                                      ),
                                            )
                                          : Container(
                                              color: AppTheme.bgCard,
                                              child: const Center(
                                                child: Text(
                                                  '👔',
                                                  style: TextStyle(
                                                    fontSize: 40,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                    Expanded(
                                      child: outfit?.bottom.imageUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  '${ApiService.baseUrl}${outfit!.bottom.imageUrl}',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                        color: AppTheme.bgCard,
                                                      ),
                                            )
                                          : Container(
                                              color: AppTheme.bgCard,
                                              child: const Center(
                                                child: Text(
                                                  '👖',
                                                  style: TextStyle(
                                                    fontSize: 40,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                        ),

                        // Dark Scrim Overlay
                        Positioned.fill(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _showStyleOverlay ? 0.6 : 0.0,
                            child: Container(color: Colors.black),
                          ),
                        ),

                        // Text Overlay (Conditional Visibility)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _showStyleOverlay ? 1.0 : 0.0,
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
                                        // styleDescription (Always visible when box is open)
                                        Text(
                                          styleDescription,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Weather Summary from TodaysPick
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            todaysPick.weatherSummary,
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (outfit != null)
                                          Text(
                                            '${outfit.top.color} & ${outfit.bottom.color}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        if (reasoning != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            reasoning,
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
                                              '${(score * 100).round()}%',
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
                                  const SizedBox(height: 12),
                                  // Detail Button inside the box
                                  if (outfit != null)
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  OutfitDetailScreen(
                                                    outfit: outfit,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'VIEW DETAILS',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => Container(
                height: 750,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
              error: (error, stack) => Container(
                height: 750,
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
    final chatState = ref.watch(chatProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Chat with AI', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {
                ref.read(chatProvider.notifier).clearChat();
              },
              child: const Text(
                'Clear History',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 638,
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
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatState.messages[index];
                    final isUser = msg.isUser;

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 280),
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
                          msg.text,
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
              if (chatState.isLoading)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(
                        12,
                      ).copyWith(topLeft: const Radius.circular(2)),
                    ),
                    child:
                        Text(
                              "로딩중...",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .fade(duration: 800.ms, begin: 0.4, end: 1.0),
                  ),
                ).animate().fade(duration: 200.ms).slideX(begin: -0.1, end: 0),
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

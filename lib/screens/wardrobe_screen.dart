import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import '../providers/wardrobe_provider.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';
import 'wardrobe_new_screen.dart';
import '../utils/responsive_helper.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _wardrobeTabController;
  final List<String> _wardrobeSubTabs = ['All', 'Tops', 'Bottoms'];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _wardrobeTabController = TabController(
      length: _wardrobeSubTabs.length,
      vsync: this,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _wardrobeTabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user scrolls near the bottom
      ref.read(wardrobeProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Closet'),
        backgroundColor: AppTheme.bgDark,
        bottom: TabBar(
          controller: _wardrobeTabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.white70,
          tabs: _wardrobeSubTabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _wardrobeTabController,
        children: _wardrobeSubTabs.map((currentTab) {
          return _buildWardrobeGrid(currentTab);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WardrobeNewScreen()),
          ).then((_) {
            ref.read(wardrobeProvider.notifier).refresh();
          });
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildWardrobeGrid(String category) {
    final itemsAsync = ref.watch(wardrobeProvider);

    return itemsAsync.when(
      data: (allItems) {
        final items = category == 'All'
            ? allItems
            : allItems
                  .where(
                    (i) => i.category == category || i.subCategory == category,
                  )
                  .toList();

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.shirt, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'No items in $category',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        final isWeb = ResponsiveHelper.isWeb(context);

        return GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.zero, // Remove padding for edge-to-edge
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWeb ? 5 : 3, // 3 cols for mobile
            crossAxisSpacing: 1, // Tiny spacing
            mainAxisSpacing: 1,
            childAspectRatio: 1.0, // Square
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  // No border radius for IG look
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: item.imageUrl!.startsWith('http')
                            ? item.imageUrl!
                            : '${ApiService.baseUrl}${item.imageUrl}',
                        fit: BoxFit.cover,
                        memCacheWidth: 400, // Optimize memory for grid
                        errorWidget: (context, url, error) {
                          print(
                            'Image Load Error for $url: $error',
                          ); // Log to console
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.alertCircle,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Error',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      const Center(
                        child: Text('👔', style: TextStyle(fontSize: 24)),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, s) => Center(
        child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

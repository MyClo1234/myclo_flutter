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

  @override
  void initState() {
    super.initState();
    _wardrobeTabController = TabController(
      length: _wardrobeSubTabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _wardrobeTabController.dispose();
    super.dispose();
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
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWeb ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: '${ApiService.baseUrl}${item.imageUrl}',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Center(
                          child: Text('👔', style: TextStyle(fontSize: 24)),
                        ),
                      )
                    else
                      const Center(
                        child: Text('👔', style: TextStyle(fontSize: 24)),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.black54,
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
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

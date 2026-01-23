import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import 'item_detail_screen.dart';
import 'wardrobe_new_screen.dart';
import '../providers/wardrobe_provider.dart';
import '../services/api_service.dart';
import '../utils/responsive_helper.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen>
    with TickerProviderStateMixin {
  late TabController _wardrobeTabController;
  final List<String> _wardrobeSubTabs = ['All', 'Tops', 'Bottoms'];

  @override
  void initState() {
    super.initState();
    _wardrobeTabController = TabController(
      initialIndex: 0,
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
        bottom: TabBar(
          controller: _wardrobeTabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          dividerColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          tabs: _wardrobeSubTabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: ResponsiveWrapper(
        maxWidth: 1200,
        child: TabBarView(
          controller: _wardrobeTabController,
          children: _wardrobeSubTabs.map((currentTab) {
            return _buildWardrobeGrid(currentTab);
          }).toList(),
        ),
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
        backgroundColor: Colors.white,
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
            child: Text(
              'No items in $category',
              style: const TextStyle(color: Colors.white54),
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

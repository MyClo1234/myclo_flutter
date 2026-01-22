import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import 'item_detail_screen.dart';
import 'wardrobe_new_screen.dart';
import '../providers/wardrobe_provider.dart';

import '../services/api_service.dart'; // Needed for ApiService.baseUrl if static
import '../providers/auth_provider.dart';
import '../utils/responsive_helper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _wardrobeTabController;

  final List<String> _tabs = ['profile', 'wardrobe', 'calendar', 'settings'];
  final List<String> _wardrobeSubTabs = ['All', 'Tops', 'Bottoms'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 0,
      length: _tabs.length,
      vsync: this,
    );
    _wardrobeTabController = TabController(
      initialIndex: 0,
      length: _wardrobeSubTabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wardrobeTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final username = authState.username ?? 'User';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Premium Member',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  tabs: _tabs.map((tab) => _buildTab(tab)).toList(),
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: ResponsiveWrapper(
          maxWidth: 1200,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(),
              _buildWardrobeTab(),
              _buildCalendarTab(),
              _buildSettingsTab(),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return _tabController.index == 1
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WardrobeNewScreen(),
                      ),
                    ).then((_) {
                      ref.read(wardrobeProvider.notifier).refresh();
                    });
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(LucideIcons.plus),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTab(String label) {
    final map = {
      'profile': 'Body Profile',
      'wardrobe': 'Wardrobe',
      'calendar': 'Calendar',
      'settings': 'Settings',
    };

    return Tab(
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          final isSelected = _tabs.indexOf(label) == _tabController.index;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              map[label]!,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white60,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWardrobeSubTab(String label) {
    return Tab(
      child: AnimatedBuilder(
        animation: _wardrobeTabController,
        builder: (context, child) {
          // Simple text tabs for sub-categories
          final isSelected =
              _wardrobeSubTabs.indexOf(label) == _wardrobeTabController.index;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileTab() {
    final authState = ref.watch(authProvider);
    final height = authState.height?.toString() ?? '-';
    final weight = authState.weight?.toString() ?? '-';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'BODY PROFILE',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Height',
                height,
                'cm',
                LucideIcons.ruler,
                AppTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Weight',
                weight,
                'kg',
                LucideIcons.user,
                AppTheme.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Display Current Body Shape
        if (authState.bodyShape != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Body Shape',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatBodyShape(authState.bodyShape!),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Image.asset(
                    'assets/images/${authState.gender == "man" ? "result_shapes_man" : "result_shapes_woman"}/${authState.bodyShape}',
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showEditProfileDialog(context, authState),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white10),
              padding: const EdgeInsets.all(16),
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit Body Profile'),
          ),
        ),
      ],
    );
  }

  String _formatBodyShape(String shape) {
    // Example: body_shape_1.png -> Type 1
    final name = shape.split('.').first;
    final parts = name.split('_');
    if (parts.length >= 3) {
      return 'Type ${parts.last}';
    }
    return shape;
  }

  void _showEditProfileDialog(BuildContext context, AuthState authState) {
    final heightController = TextEditingController(
      text: authState.height?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: authState.weight?.toString() ?? '',
    );
    String? selectedBodyShape = authState.bodyShape;
    // Fallback if null, though it shouldn't be if registered correctly
    final gender = authState.gender ?? 'man';

    final List<String> shapes = gender == 'man'
        ? [
            'body_shape_1.png',
            'body_shape_3.png',
            'body_shape_4.png',
            'body_shape_5.png',
            'body_shape_6.png',
          ]
        : [
            'body_shape_1.png',
            'body_shape_2.png',
            'body_shape_3.png',
            'body_shape_5.png',
            'body_shape_6.png',
          ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.bgDark,
            title: const Text(
              'Edit Profile',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Body Shape',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: shapes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final shape = shapes[index];
                          final isSelected = selectedBodyShape == shape;
                          final folder = gender == 'man'
                              ? 'result_shapes_man'
                              : 'result_shapes_woman';

                          return GestureDetector(
                            onTap: () {
                              setState(() => selectedBodyShape = shape);
                            },
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.white10,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      'assets/images/$folder/$shape',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Type ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () {
                  final h = int.tryParse(heightController.text) ?? 0;
                  final w = int.tryParse(weightController.text) ?? 0;
                  if (selectedBodyShape != null) {
                    ref
                        .read(authProvider.notifier)
                        .updateProfile(
                          height: h,
                          weight: w,
                          gender: gender,
                          bodyShape: selectedBodyShape!,
                        );
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withOpacity(0.5),
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textMuted)),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                    color: AppTheme.textMain,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWardrobeTab() {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: TabBar(
            controller: _wardrobeTabController,
            isScrollable: true,
            indicatorColor: Colors.transparent,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            tabs: _wardrobeSubTabs
                .map((tab) => _buildWardrobeSubTab(tab))
                .toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _wardrobeTabController,
            children: _wardrobeSubTabs.map((currentTab) {
              return _buildWardrobeGrid(currentTab);
            }).toList(),
          ),
        ),
      ],
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
            childAspectRatio: 0.75, // Better aspect ratio for images
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

  Widget _buildCalendarTab() {
    return const Center(child: Text('Calendar - Coming Soon'));
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'SETTINGS',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsItem(LucideIcons.settings, 'Preferences'),
        const SizedBox(height: 12),
        _buildSettingsItem(
          LucideIcons.logOut,
          'Sign Out',
          isDestructive: true,
          onTap: () {
            ref.read(authProvider.notifier).logout();
          },
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String label, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.redAccent : Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? Colors.redAccent : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.bgDark, // Sticky header background
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

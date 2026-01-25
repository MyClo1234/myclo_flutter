import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../providers/api_provider.dart';
import '../theme/app_theme.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final Item item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late Item _item;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final api = ref.read(apiServiceProvider);
      final json = await api.fetchWardrobeItemDetail(_item.id);

      if (mounted) {
        setState(() {
          // Merge or replace. Since the API returns the full object structure:
          // We need to parse it back to Item.
          // Assuming Item.fromJson handles the partial fields properly.
          _item = Item.fromJson(json);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _item.imageUrl!.startsWith('http')
                          ? _item.imageUrl!
                          : '${ApiService.baseUrl}${_item.imageUrl}',
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppTheme.bgCard,
                      child: const Center(
                        child: Icon(
                          LucideIcons.shirt,
                          size: 64,
                          color: Colors.white24,
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _item.subCategory,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            _item.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.edit2, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStat(
                          LucideIcons.tag,
                          'Worn',
                          '12 times',
                          AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStat(
                          LucideIcons.calendar,
                          'Last worn',
                          '2 days ago',
                          AppTheme.accent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DETAILS',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Category', _item.category),
                        const Divider(color: Colors.white10, height: 24),
                        _buildDetailRow('Color', _item.color),
                        const Divider(color: Colors.white10, height: 24),
                        _buildDetailRow('Brand', 'Unknown'), // Mock
                        // Add more fields if available from detailed fetch
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

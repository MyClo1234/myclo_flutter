import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class WardrobeNewScreen extends ConsumerStatefulWidget {
  const WardrobeNewScreen({super.key});

  @override
  ConsumerState<WardrobeNewScreen> createState() => _WardrobeNewScreenState();
}

class _WardrobeNewScreenState extends ConsumerState<WardrobeNewScreen> {
  final List<FileObj> _files = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages(ImageSource source) async {
    try {
      final List<XFile> pickedFiles;
      if (source == ImageSource.gallery) {
        pickedFiles = await _picker.pickMultiImage();
      } else {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
        );
        pickedFiles = photo != null ? [photo] : [];
      }

      if (pickedFiles.isNotEmpty) {
        _addFiles(pickedFiles);
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  void _addFiles(List<XFile> files) {
    setState(() {
      for (var file in files) {
        _files.add(FileObj(file: file));
      }
    });
    _processFiles();
  }

  Future<void> _processFiles() async {
    final api = ref.read(apiServiceProvider);

    for (var fileObj in _files) {
      if (fileObj.status == 'pending') {
        setState(() {
          fileObj.status = 'processing';
          fileObj.progress = 20;
        });

        try {
          setState(() {
            fileObj.progress = 50;
          });

          // Extract Attributes (API Upload)
          // API now accepts a list and returns a list
          final dataList = await api.extractAttributes([fileObj.file]);

          if (mounted && dataList.isNotEmpty) {
            setState(() {
              fileObj.status = 'completed';
              // The API returns [{ "image_url": "...", "item_id": "..." }]
              // attributes are not returned in the new schema, but we assign the map
              // so we have the ID at least.
              fileObj.attributes = dataList[0];
              fileObj.progress = 100;
            });

            // Trigger background refresh of the wardrobe list immediately after success
            ref.read(wardrobeProvider.notifier).refresh();
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              fileObj.status = 'error';
              fileObj.error = e.toString();
              fileObj.progress = 0;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Items'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsiveWrapper(
        maxWidth: 1000,
        child: Column(
          children: [
            Expanded(
              child: _files.isEmpty ? _buildEmptyState() : _buildFileList(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _pickImages(ImageSource.gallery),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.image, size: 48, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'Tap to select images',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _pickImages(ImageSource.camera),
            icon: const Icon(LucideIcons.camera),
            label: const Text('Take Photo'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    final isWeb = ResponsiveHelper.isWeb(context);

    if (isWeb) {
      return GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final obj = _files[index];
          return _buildFileItem(obj, index);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final obj = _files[index];
        return _buildFileItem(obj, index);
      },
    );
  }

  Widget _buildFileItem(FileObj obj, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: kIsWeb
                    ? NetworkImage(obj.file.path)
                    : FileImage(File(obj.file.path)) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obj.file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (obj.status == 'processing')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: obj.progress / 100,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'AI Analyzing...',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  )
                else if (obj.status == 'completed')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.checkCircle,
                            size: 14,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${obj.attributes?['color']?['primary']} ${obj.attributes?['category']?['sub']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else if (obj.status == 'error')
                  Text(
                    obj.error ?? 'Error',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.x,
              size: 18,
              color: AppTheme.textMuted,
            ),
            onPressed: () {
              setState(() {
                _files.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final completedCount = _files.where((f) => f.status == 'completed').length;
    final allDone =
        _files.isNotEmpty &&
        completedCount + _files.where((f) => f.status == 'error').length ==
            _files.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickImages(ImageSource.gallery),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add More'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (allDone) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Finish ($completedCount)'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FileObj {
  final XFile file;
  String status; // pending, processing, completed, error
  double progress;
  Map<String, dynamic>? attributes;
  String? error;

  FileObj({
    required this.file,
    this.status = 'pending',
    this.progress = 0,
    this.attributes,
    this.error,
  });
}

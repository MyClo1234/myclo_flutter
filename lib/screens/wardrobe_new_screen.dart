import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';
import '../services/pose_service.dart';
import '../widgets/pose_painter.dart';
import '../theme/app_theme.dart';
import 'body_check_screen.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:ui' as ui;

class WardrobeNewScreen extends ConsumerStatefulWidget {
  const WardrobeNewScreen({super.key});

  @override
  ConsumerState<WardrobeNewScreen> createState() => _WardrobeNewScreenState();
}

class _WardrobeNewScreenState extends ConsumerState<WardrobeNewScreen> {
  final List<FileObj> _files = [];
  final ImagePicker _picker = ImagePicker();
  final PoseService _poseService = PoseService(); // Instance for analysis

  @override
  void dispose() {
    _poseService.close();
    super.dispose();
  }

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

  Future<void> _openBodyCheckCamera() async {
    // Navigate to body check screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BodyCheckScreen()),
    );

    // If we got a result (path), add it
    if (result != null && result is String) {
      // Mocking XFile from string path for consistency
      final file = XFile(result);
      _addFiles([file]);
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
          // 1. Run Pose Detection first (Real Analysis)
          final result = await _poseService.processFile(fileObj.file.path);
          final status = result['status'] as BodyStatus;
          final pose = result['pose'] as Pose?;

          fileObj.bodyStatus = status;
          fileObj.pose = pose; // Store for visualization

          if (status == BodyStatus.noBody) {
            // If really no body, might just be clothes flat lay.
            // But for this feature request "Detect after photo", we can flag it.
            // We'll proceed but mark warning.
          }

          setState(() {
            fileObj.progress = 60;
          });

          // 2. Extract Attributes (Mock API for clothes data)
          final data = await api.extractAttributes(fileObj.file);

          if (mounted) {
            setState(() {
              fileObj.status = 'completed';
              fileObj.attributes = data['attributes'];
              // Add a tag if pose analysis detected something useful?
              if (status == BodyStatus.fullBody) {
                fileObj.attributes?['notes'] = "Full Body Shot";
              }
              fileObj.progress = 100;
            });
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
      body: Column(
        children: [
          Expanded(
            child: _files.isEmpty ? _buildEmptyState() : _buildFileList(),
          ),
          _buildBottomBar(),
        ],
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
                border: Border.all(
                  color: Colors.white10,
                  style: BorderStyle.none,
                ), // Dashed border not easy in flutter default
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
            onPressed: () => _openBodyCheckCamera(),
            icon: const Icon(LucideIcons.camera),
            label: const Text('Take Photo (Body Check)'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final obj = _files[index];
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
                    image: FileImage(File(obj.file.path)),
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
                          // Detection Status Indicator
                          if (obj.bodyStatus != null)
                            GestureDetector(
                              onTap: () => _showDetectionDialog(obj),
                              child: Row(
                                children: [
                                  Icon(
                                    obj.bodyStatus == BodyStatus.fullBody
                                        ? LucideIcons.checkCheck
                                        : LucideIcons.alertCircle,
                                    size: 12,
                                    color: obj.bodyStatus == BodyStatus.fullBody
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    obj.bodyStatus == BodyStatus.fullBody
                                        ? 'Full Body (Tap to view)'
                                        : 'Partial Body',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          obj.bodyStatus == BodyStatus.fullBody
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
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
      },
    );
  }

  void _showDetectionDialog(FileObj obj) {
    if (obj.pose == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text("Detection Result")),
            body: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // In a real app we need to know the image size to scale the painter correctly.
                  // For now, we will assume the image fits in the view and pass generic size
                  // Or simpler: just display the text result if scaling is hard with static file.

                  // Actually, let's try to load the image to get size for the painter
                  return FutureBuilder<ui.ImageDescriptor>(
                    future: _getImageSize(obj.file),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const CircularProgressIndicator();

                      final imgSize = Size(
                        snapshot.data!.width.toDouble(),
                        snapshot.data!.height.toDouble(),
                      );

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(obj.file.path), fit: BoxFit.contain),
                          CustomPaint(
                            painter: PosePainter(
                              obj.pose!,
                              imgSize,
                              InputImageRotation
                                  .rotation0deg, // Files are usually upright or handled by EXIF
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<ui.ImageDescriptor> _getImageSize(XFile file) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      await file.readAsBytes(),
    );
    return await ui.ImageDescriptor.encoded(buffer);
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

  // New fields for detection result
  Pose? pose;
  BodyStatus? bodyStatus;

  FileObj({
    required this.file,
    this.status = 'pending',
    this.progress = 0,
    this.attributes,
    this.error,
    this.pose,
    this.bodyStatus,
  });
}

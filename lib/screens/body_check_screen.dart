import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_service.dart';
import '../widgets/pose_painter.dart';
import '../theme/app_theme.dart';

class BodyCheckScreen extends StatefulWidget {
  const BodyCheckScreen({super.key});

  @override
  State<BodyCheckScreen> createState() => _BodyCheckScreenState();
}

class _BodyCheckScreenState extends State<BodyCheckScreen> {
  CameraController? _controller;
  final PoseService _poseService = PoseService();
  BodyStatus _status = BodyStatus.analyzing;
  Pose? _pose;
  Size? _inputImageSizeBytes;
  InputImageRotation? _rotation;
  bool _isProcessing = false;

  // Auto-capture variables
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use front camera usually for simple body check, or back for wardrobe
    // Let's default to back camera for photographing clothes/self in mirror
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // Best for Android ML Kit
    );

    await _controller!.initialize();

    // Set rotation for painter (Simplified for POV)
    _rotation = InputImageRotation.rotation90deg;

    if (!mounted) return;

    await _controller!.startImageStream((image) {
      if (_isProcessing) return;
      _isProcessing = true;

      _inputImageSizeBytes = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      _poseService
          .processImage(image, camera)
          .then((result) {
            if (mounted) {
              setState(() {
                final newStatus = result['status'] as BodyStatus;
                final newPose = result['pose'] as Pose?;

                // Update status mainly for text feedback
                _status = newStatus;

                // Only update pose if we have a new one, or if explicit no body.
                // If analyzing (busy), keep the old pose to prevent flickering.
                if (newPose != null) {
                  _pose = newPose;
                } else if (newStatus == BodyStatus.noBody) {
                  _pose = null;
                }

                // Auto-capture logic
                if (newStatus == BodyStatus.fullBody && !_isCapturing) {
                  if (_countdownTimer == null || !_countdownTimer!.isActive) {
                    _startCountdown();
                  }
                } else {
                  // Reset if lost body tracking (but ignore if analyzing/tooClose flicker)
                  if (newStatus == BodyStatus.noBody ||
                      newStatus == BodyStatus.upperBodyOnly) {
                    _resetCountdown();
                  }
                }
              });
            }
          })
          .whenComplete(() => _isProcessing = false);
    });

    setState(() {});
  }

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 1) {
            _countdown--;
          } else {
            _countdownTimer?.cancel();
            _capturePhoto();
          }
        });
      }
    });
  }

  void _resetCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdown = 3;
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      await _controller?.stopImageStream();
      final XFile file = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, file.path);
      }
    } catch (e) {
      print("Error capturing: $e");
      setState(() {
        _isCapturing = false;
        _resetCountdown();
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller?.dispose();
    _poseService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(child: CameraPreview(_controller!)),

          // Overlay Guide
          _buildOverlay(),

          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom Feedback Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFeedbackPanel(),
          ),

          // Debug Info Overlay
          Positioned(top: 100, left: 20, child: _buildDebugInfo()),
        ],
      ),
    );
  }

  Widget _buildDebugInfo() {
    if (_pose == null) return const SizedBox.shrink();

    final nose = _pose!.landmarks[PoseLandmarkType.nose]?.likelihood ?? 0;
    final leftShoulder =
        _pose!.landmarks[PoseLandmarkType.leftShoulder]?.likelihood ?? 0;
    final rightShoulder =
        _pose!.landmarks[PoseLandmarkType.rightShoulder]?.likelihood ?? 0;
    final leftAnkle =
        _pose!.landmarks[PoseLandmarkType.leftAnkle]?.likelihood ?? 0;
    final rightAnkle =
        _pose!.landmarks[PoseLandmarkType.rightAnkle]?.likelihood ?? 0;

    TextStyle style(double val) => TextStyle(
      color: val > 0.5 ? Colors.greenAccent : Colors.redAccent,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Scores:",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text("Nose: ${nose.toStringAsFixed(2)}", style: style(nose)),
          Text(
            "Shoulders: ${((leftShoulder + rightShoulder) / 2).toStringAsFixed(2)}",
            style: style((leftShoulder + rightShoulder) / 2),
          ),
          Text(
            "Ankles: ${((leftAnkle + rightAnkle) / 2).toStringAsFixed(2)}",
            style: style((leftAnkle + rightAnkle) / 2),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        // Skeleton Painter
        if (_pose != null && _inputImageSizeBytes != null && _rotation != null)
          CustomPaint(
            painter: PosePainter(_pose!, _inputImageSizeBytes!, _rotation!),
            child: Container(),
          ),

        // Simple guide box
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              border: Border.all(
                color: _status == BodyStatus.fullBody
                    ? Colors.greenAccent
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackPanel() {
    Color color;
    String text;
    IconData icon;
    bool canCapture = false;

    switch (_status) {
      case BodyStatus.fullBody:
        color = Colors.greenAccent;
        // visual feedback
        if (_isCapturing) {
          text = "Capturing...";
        } else if (_countdownTimer != null && _countdownTimer!.isActive) {
          text = "Perfect! Capturing in $_countdown...";
        } else {
          text = "Perfect! Full body visible.";
        }
        icon = LucideIcons.checkCircle;
        canCapture = true;
        break;
      case BodyStatus.upperBodyOnly:
        color = Colors.orangeAccent;
        text = "Show your feet! Step back.";
        icon = LucideIcons.moveDiagonal;
        break;
      case BodyStatus.tooClose:
        color = Colors.redAccent;
        text = "Too close! Step back.";
        icon = LucideIcons.zoomOut;
        break;
      case BodyStatus.noBody:
        color = Colors.white;
        text = "Stand in frames.";
        icon = LucideIcons.user;
        break;
      case BodyStatus.analyzing:
        color = Colors.white54;
        text = "Analyzing...";
        icon = LucideIcons.loader2;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canCapture ? _capturePhoto : null,
              child: Text(
                _isCapturing ? "Capturing..." : "Capture Photo ($_countdown)",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

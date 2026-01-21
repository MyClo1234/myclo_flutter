import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.pose, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent;

    pose.landmarks.forEach((_, landmark) {
      canvas.drawCircle(
        Offset(
          translateX(landmark.x, size, absoluteImageSize, rotation),
          translateY(landmark.y, size, absoluteImageSize, rotation),
        ),
        1,
        paint,
      );
    });

    void paintLine(
      PoseLandmarkType type1,
      PoseLandmarkType type2,
      Paint paintType,
    ) {
      final PoseLandmark joint1 = pose.landmarks[type1]!;
      final PoseLandmark joint2 = pose.landmarks[type2]!;
      canvas.drawLine(
        Offset(
          translateX(joint1.x, size, absoluteImageSize, rotation),
          translateY(joint1.y, size, absoluteImageSize, rotation),
        ),
        Offset(
          translateX(joint2.x, size, absoluteImageSize, rotation),
          translateY(joint2.y, size, absoluteImageSize, rotation),
        ),
        paintType,
      );
    }

    // Arms
    paintLine(
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      leftPaint,
    );
    paintLine(
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
      leftPaint,
    );
    paintLine(
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      rightPaint,
    );
    paintLine(
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
      rightPaint,
    );

    // Body
    paintLine(
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
      leftPaint,
    );
    paintLine(
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
      rightPaint,
    );

    // Legs
    paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
    paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
    paintLine(
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      rightPaint,
    );
    paintLine(
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
      rightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose;
  }

  double translateX(
    double x,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
  ) {
    // Determine based on rotation if we swap width/height logic
    // For simplicity assuming portrait mode (CameraImage usually rotated 90/270)
    // Actually, ML Kit imageSize is usually the raw sensor size (e.g. 640x480)

    // In Front Camera (Mirrored): return canvasSize.width - x * canvasSize.width / imageSize.width;
    // In Back Camera: return x * canvasSize.width / imageSize.height (if 90 deg)

    // Simplification for MVP assuming Back camera portrait
    // Image is coming in rotated, so image Width = canvas Height, image Height = canvas Width effectively for Aspect Ratio

    return x * canvasSize.width / imageSize.height;
  }

  double translateY(
    double y,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
  ) {
    return y * canvasSize.height / imageSize.width;
  }
}

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// 신체 감지 상태를 나타내는 열거형 (Enum)
enum BodyStatus { fullBody, upperBodyOnly, tooClose, noBody, analyzing }

class PoseService {
  // ML Kit의 포즈 감지기 인스턴스
  late final PoseDetector _poseDetector;
  // 중복 처리를 방지하기 위한 플래그 (현재 분석 중인지 여부)
  bool _isBusy = false;

  PoseService() {
    // 스트림 모드로 포즈 감지기 옵션 설정 (라이브 비디오 스트림용)
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    _poseDetector = PoseDetector(options: options);
  }

  // 서비스 종료 시 감지기 리소스 해제
  Future<void> close() async {
    await _poseDetector.close();
  }

  // 카메라 이미지를 받아 처리 (스트림용)
  Future<Map<String, dynamic>> processImage(
    CameraImage image,
    CameraDescription camera,
  ) async {
    final inputImage = _inputImageFromCameraImage(image, camera);
    if (inputImage == null)
      return {'status': BodyStatus.analyzing, 'pose': null};
    return _processInputImage(inputImage);
  }

  // 파일 이미지를 받아 처리 (사진 촬영 후 분석용)
  Future<Map<String, dynamic>> processFile(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    return _processInputImage(inputImage);
  }

  // 공통 포즈 분석 로직
  Future<Map<String, dynamic>> _processInputImage(InputImage inputImage) async {
    if (_isBusy) return {'status': BodyStatus.analyzing, 'pose': null};
    _isBusy = true;

    try {
      // 2. 포즈 감지 실행 (비동기)
      final poses = await _poseDetector.processImage(inputImage);
      // 감지된 포즈가 없으면 '몸 없음' 반환
      if (poses.isEmpty) return {'status': BodyStatus.noBody, 'pose': null};

      // 첫 번째 감지된 사람의 포즈 데이터 가져오기
      final pose = poses.first;

      // 3. 주요 랜드마크(관절 포인트) 추출
      final landmarks = pose.landmarks;

      final nose = landmarks[PoseLandmarkType.nose]; // 코
      final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]; // 왼쪽 발목
      final rightAnkle = landmarks[PoseLandmarkType.rightAnkle]; // 오른쪽 발목
      final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]; // 왼쪽 어깨
      final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]; // 오른쪽 어깨

      // 4. 화면 내 존재 확률(InFrameLikelihood) 임계값 (0.5 이상이면 화면에 있다고 판단)
      const double threshold = 0.5;

      // 각 주요 부위가 화면에 들어왔는지 확인
      bool noseVisible = (nose?.likelihood ?? 0) > threshold;
      bool anklesVisible =
          (leftAnkle?.likelihood ?? 0) > threshold &&
          (rightAnkle?.likelihood ?? 0) > threshold;
      bool shouldersVisible =
          (leftShoulder?.likelihood ?? 0) > threshold &&
          (rightShoulder?.likelihood ?? 0) > threshold;

      BodyStatus status = BodyStatus.analyzing;

      // 5. 부위별 가시성에 따른 상태 결정 로직
      if (noseVisible && anklesVisible && shouldersVisible) {
        status = BodyStatus.fullBody; // 모든 주요 부위가 보임 -> 전신
      } else if (noseVisible && shouldersVisible && !anklesVisible) {
        status = BodyStatus.upperBodyOnly; // 발목이 안 보임 -> 상반신
      } else if (noseVisible && !shouldersVisible) {
        status = BodyStatus.tooClose; // 어깨도 안 보임 -> 너무 가까움 (얼굴 위주)
      } else if (!noseVisible && anklesVisible) {
        status = BodyStatus.noBody; // 발은 보이는데 얼굴이 안 보임
      }

      // 상태와 포즈 객체를 반환 (UI 그리기용)
      return {'status': status, 'pose': pose};
    } catch (e) {
      print('Error detecting pose: $e');
      return {'status': BodyStatus.analyzing, 'pose': null};
    } finally {
      _isBusy = false;
    }
  }

  // CameraImage(raw 데이터)를 ML Kit용 InputImage로 변환하는 헬퍼 함수
  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    // 플랫폼별 이미지 회전 각도 계산
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      var rotationCompensation = _orientations[DeviceOrientation.portraitUp];
      if (rotationCompensation == null) return null;
      rotation = InputImageRotationValue.fromRawValue(
        (sensorOrientation + rotationCompensation) % 360,
      );
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (defaultTargetPlatform == TargetPlatform.android &&
            format != InputImageFormat.nv21) ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            format != InputImageFormat.bgra8888)) {
      // 기본 포맷 지원 체크
    }

    // Android NV21 포맷 처리
    if (image.planes.isEmpty) return null;
    if (image.planes.length != 3) return null;
    final plane = image.planes[0];

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format ?? InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // 이미지 평면 데이터 병합
  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (var plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
}

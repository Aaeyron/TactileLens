import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/scan/camera_service.dart';

const CameraDescription _rearCamera = CameraDescription(
  name: 'rear',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

/// A controller that never reaches the camera plugin. Opening waits for
/// [allowOpen] so tests can close a screen while the camera is opening.
class _FakeCameraController extends CameraController {
  _FakeCameraController({this.failOpen = false})
    : super(_rearCamera, ResolutionPreset.low);

  final bool failOpen;
  final Completer<void> allowOpen = Completer<void>();

  bool isOpen = false;
  int closeCount = 0;

  @override
  Future<void> initialize() async {
    await allowOpen.future;

    if (failOpen) {
      throw CameraException('fake_failure', 'The fake camera failed.');
    }

    isOpen = true;
    value = value.copyWith(isInitialized: true);
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {}

  @override
  Future<void> dispose() async {
    isOpen = false;
    closeCount++;

    // Safe: the real initialize() never ran, so no platform call is made.
    await super.dispose();
  }
}

/// Creates a CameraService whose controllers are recorded in [opened].
CameraService _service(
  List<_FakeCameraController> opened, {
  bool failOpen = false,
}) {
  return CameraService(
    loadCameras: () async => <CameraDescription>[_rearCamera],
    createController: (CameraDescription camera) {
      final _FakeCameraController controller = _FakeCameraController(
        failOpen: failOpen,
      );
      opened.add(controller);
      return controller;
    },
  );
}

void main() {
  setUp(CameraService.resetForTesting);

  test('closing the screen while the camera opens closes the camera', () async {
    final List<_FakeCameraController> controllers = <_FakeCameraController>[];
    final CameraService service = _service(controllers);

    final Future<void> opening = service.initialize();
    await pumpEventQueue();

    await service.dispose();
    controllers.single.allowOpen.complete();
    await opening;

    expect(controllers.single.isOpen, isFalse);
    expect(controllers.single.closeCount, 1);
    expect(service.isInitialized, isFalse);
  });

  test(
    'a new screen opens the camera only after the old one closed it',
    () async {
      final List<_FakeCameraController> oldControllers =
          <_FakeCameraController>[];
      final List<_FakeCameraController> newControllers =
          <_FakeCameraController>[];

      final CameraService oldScreen = _service(oldControllers);
      final Future<void> oldOpening = oldScreen.initialize();
      await pumpEventQueue();
      oldControllers.single.allowOpen.complete();
      await oldOpening;

      // Re-entering Scan while the old screen is still sliding out.
      final CameraService newScreen = _service(newControllers);
      final Future<void> newOpening = newScreen.initialize();
      await pumpEventQueue();

      expect(newControllers, isEmpty, reason: 'must wait for the old camera');

      await oldScreen.dispose();
      await pumpEventQueue();

      expect(oldControllers.single.isOpen, isFalse);
      expect(newControllers, hasLength(1));

      newControllers.single.allowOpen.complete();
      await newOpening;

      expect(newScreen.isInitialized, isTrue);

      await newScreen.dispose();
    },
  );

  test('retake reopens the camera after it was closed', () async {
    final List<_FakeCameraController> controllers = <_FakeCameraController>[];
    final CameraService service = _service(controllers);

    final Future<void> first = service.initialize();
    await pumpEventQueue();
    controllers.first.allowOpen.complete();
    await first;
    await service.dispose();

    final Future<void> second = service.initialize();
    await pumpEventQueue();
    controllers.last.allowOpen.complete();
    await second;

    expect(controllers, hasLength(2));
    expect(controllers.first.isOpen, isFalse);
    expect(service.isInitialized, isTrue);

    await service.dispose();
  });

  test('a failed opening still lets the next screen open the camera', () async {
    final List<_FakeCameraController> failing = <_FakeCameraController>[];
    final CameraService failingScreen = _service(failing, failOpen: true);

    final Future<void> failedOpening = failingScreen.initialize();
    await pumpEventQueue();
    failing.single.allowOpen.complete();

    await expectLater(failedOpening, throwsA(isA<CameraException>()));
    expect(failing.single.closeCount, 1);

    final List<_FakeCameraController> working = <_FakeCameraController>[];
    final CameraService nextScreen = _service(working);
    final Future<void> opening = nextScreen.initialize();
    await pumpEventQueue();
    working.single.allowOpen.complete();
    await opening;

    expect(nextScreen.isInitialized, isTrue);

    await nextScreen.dispose();
  });
}

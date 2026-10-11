import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kernel_app/agents/media_picker_service.dart';

class PhotoPicker extends ImagePicker {
  XFile? result;
  Object? error;
  ImageSource? source;
  double? width;
  double? height;
  int? quality;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    width = maxWidth;
    height = maxHeight;
    quality = imageQuality;
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.kernel.sense_ai/chat_media');
  late List<MethodCall> calls;
  Map<String, dynamic>? nativeResult;
  Map<String, dynamic>? adoptedPhoto;
  PlatformException? nativeError;
  File? ownedPhoto;
  setUp(() {
    calls = [];
    nativeResult = null;
    adoptedPhoto = null;
    nativeError = null;
    ownedPhoto = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'release') {
            if (ownedPhoto?.existsSync() ?? false) ownedPhoto!.deleteSync();
            return null;
          }
          if (nativeError != null) throw nativeError!;
          return call.method == 'adoptImagePickerCopy'
              ? adoptedPhoto
              : nativeResult;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test(
    'WAV uses bounded native import instead of file_picker copying',
    () async {
      nativeResult = {
        'path': 'owned.wav',
        'fileName': 'field.WAV',
        'token': 'lease',
      };
      final service = MediaPickerService();
      final result = await service.pickAudioFile();
      expect(calls.map((call) => call.method), ['pickWav']);
      expect(result!.path, 'owned.wav');
      expect(result.fileName, 'field.WAV');
      expect(result.isAudio, isTrue);
      expect(result.bytes, isEmpty);
      expect(result.ownershipToken, 'lease');
      await service.release(result);
      expect(calls.last.arguments, {'token': 'lease'});
      expect(
        File('lib/agents/media_picker_service.dart').readAsStringSync(),
        isNot(contains('pickFiles(')),
      );
    },
  );

  test(
    'unsupported or unreadable recordings fail and release native ownership',
    () async {
      for (final result in [
        {'fileName': 'field.wav', 'token': 'lease'},
        {'path': '', 'fileName': 'field.wav', 'token': 'lease'},
        {'path': 'owned.wav', 'fileName': 'field.mp3', 'token': 'lease'},
      ]) {
        nativeResult = result;
        await expectLater(
          MediaPickerService().pickAudioFile(),
          throwsA(isA<FileSystemException>()),
        );
        expect(calls.last.method, 'release');
      }
    },
  );

  test('unowned paths are never passed for deletion', () async {
    final root = Directory.systemTemp.createTempSync('picker-original-');
    addTearDown(() => root.deleteSync(recursive: true));
    final original = File('${root.path}/source.wav')..writeAsBytesSync([1]);
    await MediaPickerService().release(
      PickedMedia(
        path: original.path,
        fileName: 'source.wav',
        bytes: Uint8List(0),
        mediaType: 'audio',
      ),
    );
    expect(calls, isEmpty);
    expect(original.existsSync(), isTrue);
  });

  test(
    'picker cancellation is silent but platform failures propagate',
    () async {
      final photo = PhotoPicker();
      final service = MediaPickerService(imagePicker: photo);
      expect(await service.pickAudioFile(), isNull);
      expect(await service.pickImage(), isNull);
      nativeError = PlatformException(code: 'permission_denied');
      photo.error = StateError('permission denied');
      await expectLater(
        service.pickAudioFile(),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(service.pickImage(), throwsA(same(photo.error)));
    },
  );

  test(
    'photo forwards selected bytes and existing resize options unchanged',
    () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final photo = PhotoPicker()
        ..result = XFile.fromData(bytes, path: 'picked.png');
      final result = await MediaPickerService(imagePicker: photo)
          .pickImage(source: ImageSource.camera);
      expect(result!.bytes, bytes);
      expect(result.fileName, 'picked.png');
      expect(result.isImage, isTrue);
      expect(photo.source, ImageSource.camera);
      expect(photo.width, 1920);
      expect(photo.height, 1920);
      expect(photo.quality, 85);
    },
  );

  test(
    'empty or oversized photos are rejected before retaining bytes',
    () async {
      for (final size in [0, 12 * 1024 * 1024 + 1]) {
        final picker = PhotoPicker()
          ..result = XFile.fromData(Uint8List(size), name: 'photo.png');
        await expectLater(
          MediaPickerService(imagePicker: picker).pickImage(),
          throwsA(isA<FileSystemException>()),
        );
      }
    },
  );

  test(
    'owned photo copy is released even if reading or size validation fails',
    () async {
      final root = Directory.systemTemp.createTempSync('picker-photo-');
      addTearDown(() => root.deleteSync(recursive: true));
      final original = File('${root.path}/original.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final copy = File('${root.path}/owned.image')..writeAsBytesSync([]);
      ownedPhoto = copy;
      adoptedPhoto = {
        'path': copy.path,
        'fileName': 'photo.jpg',
        'token': 'photo-lease',
      };
      final photo = PhotoPicker()..result = XFile(original.path);
      await expectLater(
        MediaPickerService(imagePicker: photo).pickImage(),
        throwsA(isA<FileSystemException>()),
      );
      expect(copy.existsSync(), isFalse);
      expect(original.existsSync(), isTrue);
      expect(calls.last.arguments, {'token': 'photo-lease'});
    },
  );

  test(
    'unsupported video API is removed rather than routing bytes as a photo',
    () {
      final source = File('lib/agents/media_picker_service.dart')
          .readAsStringSync();
      expect(source, isNot(contains('pickVideo(')));
      expect(source, isNot(contains('isVideo')));
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:audio_ai/audio_ai.dart';
import 'package:audio_ai/audio_ai_platform_interface.dart';
import 'package:audio_ai/audio_ai_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudioAiPlatform
    with MockPlatformInterfaceMixin
    implements AudioAiPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AudioAiPlatform initialPlatform = AudioAiPlatform.instance;

  test('$MethodChannelAudioAi is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAudioAi>());
  });

  test('getPlatformVersion', () async {
    AudioAi audioAiPlugin = AudioAi();
    MockAudioAiPlatform fakePlatform = MockAudioAiPlatform();
    AudioAiPlatform.instance = fakePlatform;

    expect(await audioAiPlugin.getPlatformVersion(), '42');
  });
}

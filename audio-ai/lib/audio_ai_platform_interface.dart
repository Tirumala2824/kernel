import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'audio_ai_method_channel.dart';

abstract class AudioAiPlatform extends PlatformInterface {
  /// Constructs a AudioAiPlatform.
  AudioAiPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioAiPlatform _instance = MethodChannelAudioAi();

  /// The default instance of [AudioAiPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudioAi].
  static AudioAiPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AudioAiPlatform] when
  /// they register themselves.
  static set instance(AudioAiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

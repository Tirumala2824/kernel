
import 'audio_ai_platform_interface.dart';

class AudioAi {
  Future<String?> getPlatformVersion() {
    return AudioAiPlatform.instance.getPlatformVersion();
  }
}

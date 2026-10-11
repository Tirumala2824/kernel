import '../../agents/orchestrator_agent.dart';

import 'package:kernel_contracts/kernel_contracts.dart';

abstract final class ChatCopy {
  static const soundDisclaimer =
      'Experimental insect sound match — not a grain-pest diagnosis';
  static const soundScope =
      'Matches only 32 audible insect species. It cannot confirm hidden grain pests or detect ultrasound. '
      'AI-estimated — not calibrated. Noise and non-insect sounds can also match; '
      'a label does not confirm an insect is present.';
  static const modelDetails = 'Model details';
  static String soundIdentification(InsectSoundResult sound) {
    if (sound.status != InsectSoundStatus.evaluated ||
        sound.level == InsectIdentificationLevel.unknown ||
        sound.label == null ||
        sound.label!.trim().isEmpty) {
      return 'Insect sound: unknown';
    }
    return 'Insect sound: ${sound.label} (${sound.level.name})';
  }

  static List<String> soundFailureReasons(InsectSoundResult sound) {
    final messages = <String>{
      for (final reason in sound.reasons)
        switch (reason) {
          'empty_audio' || 'low_level_or_silence' =>
            'The recording is too quiet. Try a closer, clearer recording.',
          'no_signal_in_selected_windows' => 'No usable sound was found in the analyzed sections. Try a shorter recording around the sound.',
          'possible_clipping' => 'The recording is distorted. Reduce the recording level and try again.',
          'audio_too_long' => 'Choose a recording no longer than 30 seconds.',
          'audio_too_large' => 'Choose a WAV recording smaller than 6 MB.',
          'invalid_wav' ||
          'unsupported_wav_encoding' ||
          'unsupported_sample_rate' => 'Choose a 16-bit PCM WAV at 16, 44.1, or 48 kHz, in mono or stereo.',
          'file_unreadable' =>
            'This file could not be read. Select the recording again.',
          'platform_unavailable' =>
            'Sound analysis is not supported on this platform.',
          'asset_integrity' =>
            'The bundled sound model is damaged. Update or reinstall the app.',
          'model_unavailable' =>
            'The bundled sound model is missing. Update or reinstall the app.',
          'runtime_unavailable' => 'The sound engine cannot run on this device. An app update may be required.',
          _ =>
            sound.status == InsectSoundStatus.rejected
                ? 'This recording could not be analyzed. Try another WAV recording.'
                : 'Sound analysis is unavailable right now. Try again later.',
        },
    };
    if (messages.isEmpty) {
      messages.add(
        sound.status == InsectSoundStatus.rejected
            ? 'This recording could not be analyzed. Try another WAV recording.'
            : 'Sound analysis is unavailable right now. Try again later.',
      );
    }
    return messages.toList(growable: false);
  }

  static String revision(String revision) => 'Revision: $revision';
  static String modelId(String id) => 'Model source: $id';
  static const title = 'Kernel';
  static const menu = 'Menu';
  static const tools = 'Records & tools';
  static const settings = 'Settings';
  static const emptyTitle = 'A quieter way to check.';
  static const emptyBody =
      'Ask about grain storage, or attach a photo or WAV recording.';
  static const hint = 'Message Kernel';
  static const send = 'Send message';
  static const attach = 'Attach';
  static const photo = 'Photo';
  static const audio = 'WAV recording';
  static const remove = 'Remove';
  static const working = 'Working on this phone…';
  static const retry = 'Retry';
  static const retryExpired =
      'Reattach files or resend your message to try again.';
  static const clear = 'Clear conversation';
  static const clearBody =
      'Remove this conversation from this session? Saved records are not affected.';
  static const cancel = 'Cancel';
  static const pickerError =
      'Could not open that file. Try selecting it again.';
  static const inspection =
      'This is not proof of absence. Inspect physically before making decisions.';
  static const knowledge = 'From the local knowledge library — not a diagnosis';
  static const unknownAnimal =
      'Identification is unavailable. Keep your distance and do not handle an unknown animal.';

  static String notice(ChatNotice value) => switch (value) {
    ChatNotice.noKnowledge => 'No matching local guidance is available. Try naming the pest or storage issue, or ask a qualified professional.',
    ChatNotice.audioUnavailable => 'Audio analysis is unavailable on this phone right now. This recording has not been evaluated.',
    ChatNotice.imageUnavailable => 'Photo analysis is unavailable on this phone right now. This is not evidence that no pest is present.',
    ChatNotice.unsupportedMedia =>
      'Use a photo or a WAV recording. This attachment was not analyzed.',
    ChatNotice.requestFailed => 'This request could not finish. Your message is still here; you can retry.',
  };
  static String model(String version) => 'Model: $version — experimental';
  static String image(String name) =>
      'Photo: $name — AI-estimated, not calibrated';
  static String generated(String version) =>
      'Generated on this phone — experimental · $version';
}

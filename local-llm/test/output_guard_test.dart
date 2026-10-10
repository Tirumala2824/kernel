import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/src/output_guard.dart';

void expectAllowed(String text) {
  final r = checkOutput(tidyOutput(text));
  expect(r.allowed, isTrue, reason: 'rejected (${r.category}): $text');
}

void expectRejected(String text, GuardCategory category) {
  final r = checkOutput(tidyOutput(text));
  expect(r.category, category, reason: text);
}

void main() {
  group('accepts honest advice', () {
    for (final text in [
      'The scan heard likely insect sounds. Please open the sack and look for '
          'insects, holes or webbing. This model is experimental and can be wrong.',
      'The model heard no sign of insects. A clean result is not a guarantee, '
          'so check the grain physically before you decide anything.',
      'The recording was too noisy. Please record again in a quieter place.',
      'No result was produced for this scan. Try recording again.',
      'Of 12 sacks, 6 were clean, 2 uncertain and 1 infested. 2 sacks still '
          'need a scan. Results come from an experimental model.',
      'Reminder: scan your rice again on 24 October 2026.',
      'The scan heard no insect sounds, but this is not guaranteed. Open the '
          'sack and look.',
      // Hindi: inspect physically, experimental, no guarantee.
      'स्कैन में कीड़ों जैसी आवाज़ सुनाई दी। बोरी खोलकर अनाज को खुद जांचें। '
          'यह मॉडल प्रयोगात्मक है, गारंटी नहीं।',
      // Tamil: please check the sack.
      'மூட்டையைத் திறந்து தானியத்தைப் பார்க்கவும்.',
    ]) {
      test(text.substring(0, 30), () => expectAllowed(text));
    }

    test('markdown emphasis is tidied, not rejected', () {
      expect(
        tidyOutput('**Check** the sack.\n\n\n\nThen scan again.  '),
        'Check the sack.\n\nThen scan again.',
      );
      expectAllowed('**Check** the sack by hand.');
    });
  });

  group('rejects treatment and chemicals', () {
    for (final text in [
      'You should fumigate the store room.',
      'Fumigation with phosphine will stop the insects.',
      'Use aluminium phosphide tablets.',
      'Put two Celphos tablets in the bin.',
      'Mix a little pesticide with the grain.',
      'An insecticide spray can help.',
      'Spraying malathion around the sacks helps.',
      'Do not use chemicals near food.',
      'Add neem leaves to the container.',
      'Treat the grain before storing it.',
      'Kill the weevils by drying the grain.',
      'Ek baar keetnashak dawa daal dein.',
      'Thoda dawai chhidkav karein.',
      // Hindi: pesticide; "spray medicine"; fumigation; sulphas.
      'अनाज में कीटनाशक मिलाएं।',
      'बोरी पर दवा छिड़क दें।',
      'गोदाम में फ्यूमिगेशन करवाएं।',
      'सल्फास की गोली रखें।',
      // Marathi, Bengali, Telugu, Tamil, Gujarati, Kannada, Malayalam,
      // Odia, Punjabi pesticide words.
      'कीटकनाशक वापरा.',
      'কীটনাশক ব্যবহার করুন।',
      'పురుగుమందు వాడండి.',
      'பூச்சிக்கொல்லி பயன்படுத்தவும்.',
      'જંતુનાશક વાપરો.',
      'ಕೀಟನಾಶಕ ಬಳಸಿ.',
      'കീടനാശിനി ഉപയോഗിക്കുക.',
      'କୀଟନାଶକ ବ୍ୟବହାର କରନ୍ତୁ।',
      'ਕੀਟਨਾਸ਼ਕ ਵਰਤੋ।',
    ]) {
      test(text, () => expectRejected(text, GuardCategory.treatment));
    }

    test('precomposed and decomposed nukta both match', () {
      // "chhidak" (sprinkle) with U+095C, then with U+0921 U+093C.
      final pre = String.fromCharCodes([0x091B, 0x093F, 0x095C, 0x0915]);
      final dec = String.fromCharCodes([
        0x091B,
        0x093F,
        0x0921,
        0x093C,
        0x0915,
      ]);
      expectRejected('बोरी पर $pre दें', GuardCategory.treatment);
      expectRejected('बोरी पर $dec दें', GuardCategory.treatment);
    });

    test('zero-width characters cannot split a word', () {
      final split = 'Use pesti${String.fromCharCode(0x200B)}cide now.';
      expectRejected(split, GuardCategory.treatment);
    });
  });

  group('rejects safety claims', () {
    for (final text in [
      'Your grain is safe to eat.',
      'The sack is pest-free.',
      'The grain is free from insects.',
      'There are no insects in this sack.',
      'The lot is clean and fine.',
      'This result is guaranteed.',
      'No need to inspect the grain.',
      'आपका अनाज सुरक्षित है।',
      'अनाज कीट-मुक्त है।',
      'Anaaj surakshit hai.',
      'আপনার শস্য নিরাপদ।',
    ]) {
      test(text, () => expectRejected(text, GuardCategory.safetyClaim));
    }
  });

  group('rejects lot decisions', () {
    for (final text in [
      'You can accept this lot.',
      'Reject the lot from this supplier.',
      'The lot is approved for purchase.',
      'You should not buy this grain.',
      'Refuse the delivery.',
      'इस लॉट को स्वीकार करें।',
      'यह लॉट अस्वीकार करें।',
      'Lot ko kharij kar dein.',
    ]) {
      test(text, () => expectRejected(text, GuardCategory.decision));
    }
  });

  group('rejects links and markup', () {
    test('URLs, domains and e-mail', () {
      expectRejected(
        'See https://example.org/help for more.',
        GuardCategory.url,
      );
      expectRejected('Visit www.example.com today.', GuardCategory.url);
      expectRejected('Read kernel-help.in for tips.', GuardCategory.url);
      expectRejected('Write to help@example.com.', GuardCategory.url);
    });

    test('headings and code fences', () {
      expectRejected('# Result\nOpen the sack.', GuardCategory.markup);
      expectRejected('Result\n===\nOpen the sack.', GuardCategory.markup);
      expectRejected('```\nOpen the sack.\n```', GuardCategory.markup);
    });
  });

  test('empty and runaway output are rejected', () {
    expectRejected('   \n ', GuardCategory.empty);
    expectRejected('Check the sack. ' * 200, GuardCategory.tooLong);
  });
}

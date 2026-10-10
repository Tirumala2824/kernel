import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/src/output_guard.dart';

void expectPestAllowed(String text) {
  final r = checkPestOutput(tidyOutput(text));
  expect(r.allowed, isTrue, reason: 'rejected (${r.category}): $text');
}

void expectPestRejected(String text, GuardCategory category) {
  final r = checkPestOutput(tidyOutput(text));
  expect(r.category, category, reason: text);
}

void main() {
  group('Pest ID guidance that follows the cards is allowed', () {
    for (final text in [
      'This may be a German cockroach. The label is AI-estimated and not '
          'calibrated. Remove food and water sources and seal gaps. Call a '
          'licensed pest-control professional if you see them in daylight.',
      'This might be a scorpion; it can make you very ill. Stay well back and '
          'keep children away. If bitten or stung: get medical care.',
      'The droppings may come from rats. Store food in closed containers and '
          'seal holes. Ask an expert to check the identification.',
      // Hindi: may be a rat; keep food closed; call a professional.
      'यह शायद चूहा हो सकता है। खाना बंद डिब्बों में रखें और छेद बंद करें। '
          'ज़रूरत हो तो किसी पेशेवर को बुलाएँ।',
      // Tamil: keep away and see a doctor.
      'இதிலிருந்து விலகி இருங்கள். கடித்தால் மருத்துவரை அணுகவும்.',
    ]) {
      test(text.substring(0, 24), () => expectPestAllowed(text));
    }
  });

  group('the lead\'s required wording passes (card review)', () {
    test('protected wildlife and stay-well-back answers, English', () {
      expectPestAllowed(
        'This may be a monitor lizard, which is protected wildlife; the label '
        'is AI-estimated. Do not harm, catch or injure it; contact the State '
        'Forest Department or a licensed rescuer.',
      );
      expectPestAllowed(
        'This may be a scorpion, which has a strong sting. Stay well back and '
        'keep children away. If bitten or stung: get medical care, see a '
        'doctor or go to hospital.',
      );
    });

    test('protected wildlife and stay-well-back answers, Hindi', () {
      // "This may be a monitor lizard, which is protected. Do not harm,
      // catch or injure it; contact the State Forest Department or a
      // licensed rescuer."
      expectPestAllowed(
        'यह शायद गोह है, जो संरक्षित वन्यजीव है। इसे नुकसान न पहुँचाएँ, न '
        'पकड़ें और न घायल करें; राज्य वन विभाग या लाइसेंस प्राप्त बचावकर्ता से '
        'संपर्क करें।',
      );
      // "Stay well back. If bitten or stung: see a doctor or go to hospital."
      expectPestAllowed(
        'यह शायद बिच्छू है। दूर रहें और बच्चों को दूर रखें। काटने या डंक लगने '
        'पर: डॉक्टर को दिखाएँ या अस्पताल जाएँ।',
      );
    });

    test('the old wording is still rejected (no allowances)', () {
      // "kill" stays blocked even when negated; the cards now say
      // "catch or injure" instead.
      expectPestRejected(
        'Do not harm, capture or kill it; contact the State Forest Department.',
        GuardCategory.treatment,
      );
      expectPestRejected('Keep a safe distance.', GuardCategory.safetyClaim);
      expectPestRejected('For your safety, stay away.', GuardCategory.safetyClaim);
      expectPestRejected('Get medical treatment for a sting.', GuardCategory.treatment);
      expectPestRejected('First aid: wash with medicine.', GuardCategory.treatment);
      expectPestRejected('सुरक्षित दूरी बनाए रखें।', GuardCategory.safetyClaim);
      expectPestRejected('डॉक्टर से उपचार लें।', GuardCategory.treatment);
      expectPestRejected(
        'The species needs to be confirmed by an expert.',
        GuardCategory.certainty,
      );
    });
  });

  group('rodenticides, poisons and doses are rejected', () {
    for (final text in [
      'Place bromadiolone blocks along the wall.',
      'Brodifacoum bait works within days.',
      'Mix zinc phosphide with flour.',
      'Use aluminium phosphide in the burrow.',
      'Warfarin is an old rat poison.',
      'Buy some rat poison from the market.',
      'Put rat kill cakes near the hole.',
      'Set up a bait station near the drain.',
      'Use 5 g per burrow.',
      'The correct dose is two pellets.',
      'Chuha maar dawa daal dijiye.',
      'Chuhe maarne ki goli rakhein.',
      'Ratol paste lagayein.',
      'Thoda zehreela khana rakh do.',
      // Hindi
      'चूहा मार दवा रखें।',
      'चूहे मार गोली डालें।',
      'थोड़ा ज़हर मिला दें।',
      'रैटोल लगाएँ।',
      // Bengali, Telugu, Tamil, Malayalam, Gujarati, Punjabi
      'ইঁদুর মারা বিষ দিন।',
      'ఎలుకల మందు పెట్టండి।',
      'எலி மருந்து வைக்கவும்.',
      'എലിവിഷം വയ്ക്കുക.',
      'ઝેર મૂકો.',
      'ਚੂਹੇ ਮਾਰ ਦਵਾਈ ਪਾਓ।',
      // Existing treatment terms stay rejected in Pest ID text.
      'Spray insecticide in the corners.',
      'Fumigate the store room.',
    ]) {
      test(text, () => expectPestRejected(text, GuardCategory.treatment));
    }

    test('the shared advice guard rejects the new rodenticide terms too', () {
      for (final text in [
        'Put bromadiolone near the sacks.',
        'Use chuha maar near the grain.',
        'चूहा मार रखें।',
      ]) {
        expect(
          checkOutput(text).category,
          GuardCategory.treatment,
          reason: text,
        );
      }
    });
  });

  group('certainty claims are rejected', () {
    for (final text in [
      'This is definitely a German cockroach.',
      'It is certainly a rice weevil.',
      'I am sure this is a scorpion.',
      'This is 100% a rat.',
      'Without a doubt this is a krait.',
      'The species is confirmed.',
      'This is clearly a cobra.',
      'This is not a pest.',
      'Yeh pakka chuha hai.',
      // Hindi, Bengali, Tamil, Telugu, Gujarati, Punjabi
      'यह निश्चित रूप से कॉकरोच है।',
      'यह पक्का बिच्छू है।',
      'এটি নিশ্চিতভাবে তেলাপোকা।',
      'இது நிச்சயமாக கரப்பான் பூச்சி.',
      'ఇది ఖచ్చితంగా బొద్దింక.',
      'આ ચોક્કસપણે વંદો છે.',
      'ਇਹ ਯਕੀਨਨ ਚੂਹਾ ਹੈ।',
    ]) {
      test(text, () => expectPestRejected(text, GuardCategory.certainty));
    }
  });

  group('safety claims are rejected', () {
    for (final text in [
      'This spider is harmless.',
      'It is non-venomous, so you can pick it up.',
      'It is safe to touch.',
      'This snake is not dangerous.',
      "It won't bite you.",
      'There is no risk to children.',
      'Your kitchen is now pest-free.',
      'यह हानिरहित है।',
      'यह खतरनाक नहीं है।',
      'இதனால் ஆபத்து இல்லை.',
    ]) {
      test(text, () => expectPestRejected(text, GuardCategory.safetyClaim));
    }
  });

  test('approved wording never hides a treatment next to it', () {
    expectPestRejected(
      'Stay well back; spray it with insecticide instead.',
      GuardCategory.treatment,
    );
    expectPestRejected(
      'Do not harm, catch or injure it, but put rat poison nearby.',
      GuardCategory.treatment,
    );
    expectPestRejected('Kill it with a stick.', GuardCategory.treatment);
  });

  test('length, links and markup', () {
    expectPestRejected('', GuardCategory.empty);
    expectPestRejected('a' * 2001, GuardCategory.tooLong);
    expectPestRejected('See www.example.com for help.', GuardCategory.url);
    expectPestRejected('# Steps\nSeal gaps.', GuardCategory.markup);
    expect(checkPestOutput('a' * 81, maxChars: 80).category, GuardCategory.tooLong);
  });
}

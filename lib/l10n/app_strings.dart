// lib/l10n/app_strings.dart
//
// Lightweight i18n for the pre-login chain only: welcome/register-login,
// onboarding, phone entry, OTP, profile setup. Post-login screens (Home,
// Browse, Add Listing, Profile, My Trades, Notifications) are NOT covered
// here — that's a much larger scope and out of bounds for this fix.
//
// Translations are a reasonable starting point for a hackathon demo, not
// professionally reviewed — worth a native-speaker sanity check before
// judging if you have five minutes.

class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    // Welcome / Register / Login
    'welcome_title': {
      'en': 'Welcome to Village Exchange',
      'hi': 'विलेज एक्सचेंज में आपका स्वागत है',
      'te': 'విలేజ్ ఎక్స్ఛేంజ్‌కి స్వాగతం',
    },
    'welcome_subtitle': {
      'en': 'New here, or already have an account?',
      'hi': 'नए हैं या पहले से खाता है?',
      'te': 'కొత్తవారా లేదా ఇప్పటికే ఖాతా ఉందా?',
    },
    'welcome_register_button': {
      'en': 'Register',
      'hi': 'नया खाता बनाएं',
      'te': 'కొత్త ఖాతా సృష్టించండి',
    },
    'welcome_login_button': {
      'en': 'Login',
      'hi': 'लॉगिन करें',
      'te': 'లాగిన్ చేయండి',
    },

    // Language select screen (already trilingual in the UI, included here
    // for completeness / reuse)
    'select_language_title': {
      'en': 'Select your language',
      'hi': 'अपनी भाषा चुनें',
      'te': 'మీ భాషను ఎంచుకోండి',
    },

    // Onboarding — 3 slides
    'onboarding_slide1': {
      'en': 'Find what your village needs, when it needs it',
      'hi': 'आपके गाँव को जो चाहिए, जब चाहिए तब पाएं',
      'te': 'మీ గ్రామానికి ఏమి కావాలో, ఎప్పుడు కావాలో అది పొందండి',
    },
    'onboarding_slide2': {
      'en': 'List your idle equipment, tools, or produce',
      'hi': 'अपने खाली उपकरण, औज़ार या उपज को सूचीबद्ध करें',
      'te': 'మీ ఖాళీగా ఉన్న పరికరాలు, పనిముట్లు లేదా పంటను జాబితా చేయండి',
    },
    'onboarding_slide3': {
      'en': 'Speak instead of type — works in your language',
      'hi': 'टाइप करने के बजाय बोलें — यह आपकी भाषा में काम करता है',
      'te': 'టైప్ చేయడానికి బదులుగా మాట్లాడండి — ఇది మీ భాషలో పనిచేస్తుంది',
    },
    'onboarding_get_started': {
      'en': 'Get Started',
      'hi': 'शुरू करें',
      'te': 'ప్రారంభించండి',
    },

    // Phone entry
    'login_title': {
      'en': 'Enter your phone number',
      'hi': 'अपना फ़ोन नंबर दर्ज करें',
      'te': 'మీ ఫోన్ నంబర్‌ను నమోదు చేయండి',
    },
    'login_phone_hint': {
      'en': 'Phone Number',
      'hi': 'फ़ोन नंबर',
      'te': 'ఫోన్ నంబర్',
    },
    'login_send_otp_button': {
      'en': 'Send OTP',
      'hi': 'ओटीपी भेजें',
      'te': 'OTP పంపండి',
    },

    // OTP screen
    'otp_title': {
      'en': 'Enter the OTP sent to your phone',
      'hi': 'अपने फ़ोन पर भेजा गया ओटीपी दर्ज करें',
      'te': 'మీ ఫోన్‌కు పంపిన OTPని నమోదు చేయండి',
    },
    'otp_verify_button': {
      'en': 'Verify OTP',
      'hi': 'ओटीपी सत्यापित करें',
      'te': 'OTPని ధృవీకరించండి',
    },
    'otp_resend_button': {
      'en': 'Resend OTP',
      'hi': 'ओटीपी दोबारा भेजें',
      'te': 'OTPని మళ్లీ పంపండి',
    },
    // Deliberately left in English in all locales — it's a kIsDebug-only
    // developer hint, never shown to a real user.
    'otp_demo_code_label': {
      'en': 'Demo code: 123456',
      'hi': 'Demo code: 123456',
      'te': 'Demo code: 123456',
    },

    // Profile setup
    'profile_title': {
      'en': 'Complete Your Profile',
      'hi': 'अपनी प्रोफ़ाइल पूरी करें',
      'te': 'మీ ప్రొఫైల్‌ను పూర్తి చేయండి',
    },
    'profile_subtitle': {
      'en': 'Tell us about yourself',
      'hi': 'अपने बारे में बताएं',
      'te': 'మీ గురించి మాకు చెప్పండి',
    },
    'profile_name_hint': {
      'en': 'Your Name',
      'hi': 'आपका नाम',
      'te': 'మీ పేరు',
    },
    'profile_village_hint': {
      'en': 'Village Name',
      'hi': 'गाँव का नाम',
      'te': 'గ్రామం పేరు',
    },
    'profile_location_label': {
      'en': 'Location Access',
      'hi': 'स्थान की अनुमति',
      'te': 'లొకేషన్ యాక్సెస్',
    },
    'profile_location_subtitle': {
      'en': 'Enable location to help others find resources near you',
      'hi': 'आस-पास के लोगों को संसाधन खोजने में मदद के लिए स्थान चालू करें',
      'te': 'మీ దగ్గర్లో వనరులను కనుగొనడంలో ఇతరులకు సహాయపడటానికి లొకేషన్‌ను ప్రారంభించండి',
    },
    'profile_complete_button': {
      'en': 'Complete Profile',
      'hi': 'प्रोफ़ाइल पूरी करें',
      'te': 'ప్రొఫైల్ పూర్తి చేయండి',
    },
  };

  /// Falls back to English, then to the raw key, so a missing translation
  /// never crashes the screen — it just shows English or the key name.
  static String t(String key, String languageCode) {
    return _strings[key]?[languageCode] ?? _strings[key]?['en'] ?? key;
  }
}
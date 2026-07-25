// lib/l10n/app_strings.dart
//
// App-wide i18n. Covers every screen: pre-login chain (welcome,
// onboarding, phone/OTP, profile setup) AND post-login screens (Home,
// Browse, Add Listing, Resource Detail, My Trades, Profile, Notifications
// title).
//
// KNOWN SCOPE LIMIT: notification MESSAGE TEXT (the sentence stored in
// the "notifications" table by the DB triggers, e.g. "Your request for
// X was accepted") stays English-only for now. Those triggers bake a
// finished English sentence into the row; localizing them means
// restructuring the triggers to store structured data (listing title,
// rating, etc.) instead, which is a bigger change than a string swap.
// The Notifications SCREEN TITLE below is localized; message bodies
// are not. Flagging this so it's a documented decision, not a silent gap.
//
// Translations are a reasonable starting point for a hackathon demo, not
// professionally reviewed — worth a native-speaker sanity check before
// judging if you have five minutes.

class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    // ---------- Welcome / Register / Login ----------
    'welcome_title': {
      'en': 'Welcome to Rural Trader',
      'hi': 'ग्रामीण व्यापारी में आपका स्वागत है',
      'te': 'గ్రామీణ వ్యాపారికి స్వాగతం',
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

    // ---------- Language select ----------
    'select_language_title': {
      'en': 'Select your language',
      'hi': 'अपनी भाषा चुनें',
      'te': 'మీ భాషను ఎంచుకోండి',
    },

    // ---------- Onboarding ----------
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

    // ---------- Phone entry ----------
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

    // ---------- OTP ----------
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
    'otp_demo_code_label': {
      // Debug-only developer hint, never shown to a real user — left in
      // English in all locales on purpose.
      'en': 'Demo code: 123456',
      'hi': 'Demo code: 123456',
      'te': 'Demo code: 123456',
    },

    // ---------- Profile setup ----------
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
    'profile_screen_title': {
      'en': 'Profile',
      'hi': 'प्रोफ़ाइल',
      'te': 'ప్రొఫైల్',
    },

    // ---------- Bottom nav ----------
    'nav_home': {'en': 'Home', 'hi': 'होम', 'te': 'హోమ్'},
    'nav_browse': {'en': 'Browse', 'hi': 'ब्राउज़ करें', 'te': 'బ్రౌజ్'},
    'nav_add_listing': {
      'en': 'Add Listing',
      'hi': 'लिस्टिंग जोड़ें',
      'te': 'లిస్టింగ్ జోడించండి',
    },
    'nav_profile': {'en': 'Profile', 'hi': 'प्रोफ़ाइल', 'te': 'ప్రొఫైల్'},

    // ---------- Home ----------
    'home_welcome_title': {
      'en': 'Welcome to Rural Trader!',
      'hi': 'ग्रामीण व्यापारी में आपका स्वागत है!',
      'te': 'గ్రామీణ వ్యాపారికి స్వాగతం!',
    },
    'home_logged_in_subtitle': {
      'en': 'You are now logged in',
      'hi': 'अब आप लॉग इन हैं',
      'te': 'మీరు ఇప్పుడు లాగిన్ అయ్యారు',
    },
    'home_add_listing_button': {
      'en': 'Add Listing',
      'hi': 'लिस्टिंग जोड़ें',
      'te': 'లిస్టింగ్ జోడించండి',
    },
    'home_view_impact_button': {
      'en': 'View Impact Stats',
      'hi': 'प्रभाव आँकड़े देखें',
      'te': 'ప్రభావ గణాంకాలను చూడండి',
    },
    'home_my_trades_button': {
      'en': 'My Trades',
      'hi': 'मेरे लेन-देन',
      'te': 'నా లావాదేవీలు',
    },

    // ---------- Browse ----------
    'browse_title': {
      'en': 'Browse Resources',
      'hi': 'संसाधन ब्राउज़ करें',
      'te': 'వనరులను బ్రౌజ్ చేయండి',
    },
    'browse_search_hint': {
      'en': 'Search resources...',
      'hi': 'संसाधन खोजें...',
      'te': 'వనరులను శోధించండి...',
    },
    'category_all': {'en': 'All', 'hi': 'सभी', 'te': 'అన్నీ'},
    'category_tractor': {
      'en': 'Tractor',
      'hi': 'ट्रैक्टर',
      'te': 'ట్రాక్టర్',
    },
    'category_water_pump': {
      'en': 'Water Pump',
      'hi': 'पानी पंप',
      'te': 'నీటి పంపు',
    },
    'category_generator': {
      'en': 'Generator',
      'hi': 'जनरेटर',
      'te': 'జనరేటర్',
    },
    'category_tools': {'en': 'Tools', 'hi': 'औज़ार', 'te': 'పనిముట్లు'},
    'category_produce': {'en': 'Produce', 'hi': 'उपज', 'te': 'పంట'},
    'category_other': {'en': 'Other', 'hi': 'अन्य', 'te': 'ఇతర'},
    'status_available': {
      'en': 'Available',
      'hi': 'उपलब्ध',
      'te': 'అందుబాటులో ఉంది',
    },
    'status_requested': {
      'en': 'Requested',
      'hi': 'अनुरोधित',
      'te': 'అభ్యర్థించబడింది',
    },
    'badge_verified': {
      'en': 'Verified',
      'hi': 'सत्यापित',
      'te': 'ధృవీకరించబడింది',
    },
    'badge_new_trader': {
      'en': 'New trader',
      'hi': 'नया व्यापारी',
      'te': 'కొత్త వ్యాపారి',
    },
    'badge_member': {'en': 'Member', 'hi': 'सदस्य', 'te': 'సభ్యుడు'},
    'badge_flagged': {
      'en': 'Flagged',
      'hi': 'चिह्नित',
      'te': 'ఫ్లాగ్ చేయబడింది',
    },

    // ---------- Add Listing ----------
    'add_listing_title': {
      'en': 'Add Listing',
      'hi': 'लिस्टिंग जोड़ें',
      'te': 'లిస్టింగ్ జోడించండి',
    },
    'add_listing_title_hint': {
      'en': 'Title',
      'hi': 'शीर्षक',
      'te': 'శీర్షిక',
    },
    'add_listing_description_hint': {
      'en': 'Description',
      'hi': 'विवरण',
      'te': 'వివరణ',
    },
    'add_listing_category_label': {
      'en': 'Category',
      'hi': 'श्रेणी',
      'te': 'వర్గం',
    },
    'exchange_rent': {'en': 'Rent', 'hi': 'किराया', 'te': 'అద్దె'},
    'exchange_lend': {'en': 'Lend', 'hi': 'उधार', 'te': 'అప్పుగా'},
    'exchange_sell': {'en': 'Sell', 'hi': 'बेचें', 'te': 'అమ్మండి'},
    'exchange_exchange': {
      'en': 'Exchange',
      'hi': 'अदला-बदली',
      'te': 'మార్పిడి',
    },
    'add_listing_exchange_type_label': {
      'en': 'Exchange Type',
      'hi': 'विनिमय प्रकार',
      'te': 'మార్పిడి రకం',
    },
    'add_listing_title_required': {
      'en': 'Please enter a title',
      'hi': 'कृपया एक शीर्षक दर्ज करें',
      'te': 'దయచేసి ఓ శీర్షికను నమోదు చేయండి',
    },
    'add_listing_description_required': {
      'en': 'Please enter a description',
      'hi': 'कृपया एक विवरण दर्ज करें',
      'te': 'దయచేసి వివరణ నమోదు చేయండి',
    },
    'add_listing_location_required': {
      'en': 'Please capture your location',
      'hi': 'कृपया अपना स्थान कैप्चर करें',
      'te': 'దయచేసి మీ లొకేషన్‌ను క్యాప్చర్ చేయండి',
    },
    'add_listing_photo_label': {
      'en': 'Photo',
      'hi': 'फ़ोटो',
      'te': 'ఫోటో',
    },
    'add_listing_no_photo': {
      'en': 'No photo selected',
      'hi': 'कोई फ़ोटो चयनित नहीं',
      'te': 'ఫోటో ఎంచుకోలేదు',
    },
    'add_listing_choose_photo': {
      'en': 'Choose Photo',
      'hi': 'फ़ोटो चुनें',
      'te': 'ఫోటో ఎంచుకోండి',
    },
    'add_listing_location_label': {
      'en': 'Location',
      'hi': 'स्थान',
      'te': 'లొకేషన్',
    },
    'add_listing_location_not_captured': {
      'en': 'Location not captured',
      'hi': 'स्थान रिकॉर्ड नहीं किया गया',
      'te': 'లోకేషన్ క్యాప్చర్ చేయబడలేదు',
    },
    'add_listing_offline_queue_unsupported': {
      'en': 'Offline queueing is not supported on web. Please reconnect to submit your listing.',
      'hi': 'वेब पर ऑफ़लाइन कतारबद्ध करना समर्थित नहीं है। कृपया अपनी लिस्टिंग सबमिट करने के लिए फिर से कनेक्ट करें।',
      'te': 'వెబ్‌లో ఆఫ్లైన్ క్యూ చేయడం మద్దతు ఇవ్వబడదు. దయచేసి మీ లిస్టింగ్‌ను సమర్పించడానికి మళ్ళీ కనెక్ట్ అవ్వండి.',
    },
    'add_listing_capture_location': {
      'en': 'Capture Current Location',
      'hi': 'वर्तमान स्थान लें',
      'te': 'ప్రస్తుత లొకేషన్‌ను తీసుకోండి',
    },
    'add_listing_submit_button': {
      'en': 'Submit Listing',
      'hi': 'लिस्टिंग सबमिट करें',
      'te': 'లిస్టింగ్‌ను సమర్పించండి',
    },

    // ---------- Resource Detail ----------
    'detail_title': {
      'en': 'Resource Details',
      'hi': 'संसाधन विवरण',
      'te': 'వనరు వివరాలు',
    },
    'detail_description_label': {
      'en': 'Description',
      'hi': 'विवरण',
      'te': 'వివరణ',
    },
    'detail_owner_label': {
      'en': 'Owner',
      'hi': 'मालिक',
      'te': 'యజమాని',
    },
    'detail_unknown_owner': {
      'en': 'Unknown Owner',
      'hi': 'अज्ञात मालिक',
      'te': 'తెలియని యజమాని',
    },
    'detail_request_button': {
      'en': 'Request This',
      'hi': 'यह अनुरोध करें',
      'te': 'దీన్ని అభ్యర్థించండి',
    },
    'detail_request_sent': {
      'en': 'Request Sent',
      'hi': 'अनुरोध भेजा गया',
      'te': 'అభ్యర్థన పంపబడింది',
    },
    'detail_own_listing_message': {
      'en': 'This is your listing',
      'hi': 'यह आपकी लिस्टिंग है',
      'te': 'ఇది మీ లిస్టింగ్',
    },
    'detail_request_note': {
      'en': "By requesting, you'll be connected with the owner to arrange the exchange.",
      'hi': 'अनुरोध करने पर, आपको अदला-बदली की व्यवस्था के लिए मालिक से जोड़ा जाएगा।',
      'te': 'అభ్యర్థించడం ద్వారా, మార్పిడిని ఏర్పాటు చేయడానికి మిమ్మల్ని యజమానితో కలుపుతారు.',
    },
    'detail_ai_match_title': {
      'en': 'Why this might be a good match',
      'hi': 'यह एक अच्छा मिलान क्यों हो सकता है',
      'te': 'ఇది మంచి మ్యాచ్ ఎందుకు కావచ్చు',
    },
    'status_unavailable': {
      'en': 'Unavailable',
      'hi': 'उपलब्ध नहीं',
      'te': 'అందుబాటులో లేదు',
    },
    'detail_trades_suffix': {
      'en': 'trades',
      'hi': 'व्यापार',
      'te': 'లావాదేవీలు',
    },
    'browse_saved_offline': {
      'en': 'Showing saved listings while offline',
      'hi': 'ऑफलाइन रहते हुए सहेजी गई लिस्टिंग दिखाई जा रही हैं',
      'te': 'ఆఫ్లీన్ సమయంలో సేవ్ చేసిన లిస్టింగ్స్ చూపించబడుతున్నాయి',
    },
    'browse_loading_message': {
      'en': 'Finding nearby listings...',
      'hi': 'पास की लिस्टिंग खोज रहे हैं...',
      'te': 'సమీప లిస్టింగ్స్‌ను వెతుకుతున్నాము...',
    },
    'browse_error_title': {
      'en': 'Failed to load resources',
      'hi': 'संसाधन लोड करने में विफल',
      'te': 'వనరులను లోడ్ చేయలేకపోయాం',
    },
    'browse_try_again_button': {
      'en': 'Try Again',
      'hi': 'फिर प्रयास करें',
      'te': 'మళ్లీ ప్రయత్నించండి',
    },
    'browse_unknown_error': {
      'en': 'An unknown error occurred',
      'hi': 'एक अज्ञात त्रुटि हुई',
      'te': 'ఒక తెలియని లోపం సంభవించింది',
    },
    'browse_empty_title': {
      'en': 'No listings found',
      'hi': 'कोई लिस्टिंग नहीं मिली',
      'te': 'ఎవరూ లిస్టింగ్స్ కనబడలేదు',
    },
    'browse_empty_all_message': {
      'en': 'No listings are available right now. Add one to share with your village or check back soon.',
      'hi': 'इस समय कोई लिस्टिंग उपलब्ध नहीं है। साझा करने के लिए एक जोड़ें या बाद में फिर से जांचें।',
      'te': 'ప్రస్తుతం ఎలాంటి లిస్టింగ్‌లు అందుబాటులో లేవు. మీ గ్రామానికి పంచుకోవడానికి ఒకదాన్ని జోడించండి లేదా త్వరలో మళ్లీ తనిఖీ చేయండి.',
    },
    'browse_empty_filter_message': {
      'en': 'Try adjusting your filters to find what you need.',
      'hi': 'अपनी फ़िल्टर सेटिंग्स समायोजित करके देखें.',
      'te': 'మీ ఫిల్టర్లను సర్దుబాటు చేసి మీరు కావలసినది కనుగొనండి.',
    },

    // ---------- My Trades ----------
    'trades_title': {
      'en': 'My Trades',
      'hi': 'मेरे लेन-देन',
      'te': 'నా లావాదేవీలు',
    },
    'trades_tab_sent': {
      'en': 'Sent',
      'hi': 'भेजे गए',
      'te': 'పంపినవి',
    },
    'trades_tab_received': {
      'en': 'Received',
      'hi': 'प्राप्त',
      'te': 'అందుకున్నవి',
    },
    'trades_status_pending': {
      'en': 'Pending',
      'hi': 'लंबित',
      'te': 'పెండింగ్‌లో ఉంది',
    },
    'trades_status_accepted': {
      'en': 'Accepted',
      'hi': 'स्वीकृत',
      'te': 'ఆమోదించబడింది',
    },
    'trades_status_rejected': {
      'en': 'Rejected',
      'hi': 'अस्वीकृत',
      'te': 'తిరస్కరించబడింది',
    },
    'trades_status_completed': {
      'en': 'Completed',
      'hi': 'पूर्ण',
      'te': 'పూర్తయింది',
    },
    'trades_accept_button': {
      'en': 'Accept',
      'hi': 'स्वीकार करें',
      'te': 'అంగీకరించండి',
    },
    'trades_reject_button': {
      'en': 'Reject',
      'hi': 'अस्वीकार करें',
      'te': 'తిరస్కరించండి',
    },
    'trades_mark_completed_button': {
      'en': 'Mark Completed',
      'hi': 'पूर्ण के रूप में चिह्नित करें',
      'te': 'పూర్తయినట్లు గుర్తించండి',
    },
    'trades_leave_review_button': {
      'en': 'Leave a Review',
      'hi': 'समीक्षा दें',
      'te': 'సమీక్ష ఇవ్వండి',
    },
    'trades_report_issue_button': {
      'en': 'Report an Issue',
      'hi': 'समस्या की रिपोर्ट करें',
      'te': 'సమస్యను నివేదించండి',
    },
    'trades_to_label': {
      'en': 'To:',
      'hi': 'को:',
      'te': 'కు:',
    },
    'trades_from_label': {
      'en': 'From:',
      'hi': 'से:',
      'te': 'నుండి:',
    },
    'trades_review_dialog_title': {
      'en': 'Leave a Review',
      'hi': 'समीक्षा दें',
      'te': 'సమీక్ష ఇవ్వండి',
    },
    'trades_review_dialog_prompt': {
      'en': 'Rate your experience with',
      'hi': 'अपने अनुभव का मूल्यांकन करें',
      'te': 'మీ అనుభవాన్ని రేట్ చేయండి',
    },
    'trades_review_comment_hint': {
      'en': 'Comment (optional)',
      'hi': 'टिप्पणी (वैकल्पिक)',
      'te': 'వ్యాఖ్య (ఐచ్ఛిక)',
    },
    'trades_review_cancel_button': {
      'en': 'Cancel',
      'hi': 'रद्द करें',
      'te': 'రద్దు చేయండి',
    },
    'trades_review_submit_button': {
      'en': 'Submit Review',
      'hi': 'समीक्षा सबमिट करें',
      'te': 'సమీక్ష పంపండి',
    },
    'trades_review_submitted_message': {
      'en': 'Review submitted — trust scores will update on refresh',
      'hi': 'समीक्षा सबमिट की गई — विश्वास स्कोर ताज़ा करने पर अपडेट होंगे',
      'te': 'సమీక్ష సమర్పించబడింది — నమ్మక స్కోర్లు రిఫ్రెష్‌పై నవీకరించబడతాయి',
    },
    'trades_report_issue_title': {
      'en': 'Report an Issue',
      'hi': 'समस्या की रिपोर्ट करें',
      'te': 'సమస్యని నివేదించండి',
    },
    'trades_report_issue_category_label': {
      'en': 'Category',
      'hi': 'श्रेणी',
      'te': 'వర్గం',
    },
    'trades_report_issue_category_hint': {
      'en': 'Select category',
      'hi': 'श्रेणी चुनें',
      'te': 'వర్గాన్ని ఎంచుకోండి',
    },
    'trades_report_issue_description_label': {
      'en': 'Description',
      'hi': 'विवरण',
      'te': 'వివరణ',
    },
    'trades_report_issue_submit_button': {
      'en': 'Submit Report',
      'hi': 'रिपोर्ट सबमिट करें',
      'te': 'నివేదిక సమర్పించండి',
    },
    'trades_report_issue_submitted_message': {
      'en': 'Report submitted — trust scores will update on refresh',
      'hi': 'रिपोर्ट सबमिट की गई — विश्वास स्कोर ताज़ा करने पर अपडेट होंगे',
      'te': 'రిపోర్ట్ సమర్పించబడింది — నమ్మక స్కోర్లు రిఫ్రెష్‌పై నవీకరించబడతాయి',
    },
    'trades_issue_damaged': {
      'en': 'Damaged',
      'hi': 'क्षतिग्रस्त',
      'te': 'పగులైనది',
    },
    'trades_issue_stolen': {
      'en': 'Stolen',
      'hi': 'चोरी',
      'te': 'దొంగతనం',
    },
    'trades_issue_no_show': {
      'en': 'No-show',
      'hi': 'नॉन-शो',
      'te': 'నో-షో',
    },
    'trades_issue_other': {
      'en': 'Other',
      'hi': 'अन्य',
      'te': 'ఇతర',
    },

    // ---------- Notifications ----------
    // Screen title only — message bodies stay English (see file header).
    'notifications_title': {
      'en': 'Notifications',
      'hi': 'सूचनाएं',
      'te': 'నోటిఫికేషన్‌లు',
    },
  };

  /// Falls back to English, then to the raw key, so a missing translation
  /// never crashes a screen — it just shows English or the key name.
  static String t(String key, String languageCode) {
    return _strings[key]?[languageCode] ?? _strings[key]?['en'] ?? key;
  }

  /// Full language name for embedding in a Gemini prompt, e.g.
  /// "Please respond in ${AppStrings.languageName(lang)}." Only added for
  /// non-English so the prompt doesn't carry a redundant instruction.
  static String? languageInstruction(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'Please respond in Hindi.';
      case 'te':
        return 'Please respond in Telugu.';
      default:
        return null; // English needs no extra instruction
    }
  }
}
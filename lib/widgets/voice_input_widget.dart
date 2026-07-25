import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputWidget extends StatefulWidget {
  final Function(String) onTextReceived;

  /// Bare language code ('en', 'hi', 'te') or full BCP-47 id ('hi-IN').
  final String? initialLanguage;

  const VoiceInputWidget({
    super.key,
    required this.onTextReceived,
    this.initialLanguage,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcribedText = '';
  String _selectedLangCode = 'en';
  List<LocaleName> _availableLocales = [];

  static const _languageOptions = {
    'en': 'English',
    'hi': 'Hindi',
    'te': 'Telugu',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialLanguage != null) {
      _selectedLangCode = _normalizeLangCode(widget.initialLanguage!);
    }
    _initSpeech();
  }

  String _normalizeLangCode(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('-')) return lower.split('-').first;
    if (lower.contains('_')) return lower.split('_').first;
    return lower;
  }

  Future<void> _initSpeech() async {
    _isAvailable = await _speechToText.initialize();
    if (_isAvailable) {
      _availableLocales = await _speechToText.locales();
      if (kDebugMode) {
        print('[VoiceInput] Available speech locales (${_availableLocales.length}):');
        for (final locale in _availableLocales) {
          print('  localeId: "${locale.localeId}", name: "${locale.name}"');
        }
      }
    }
    if (mounted) setState(() {});
  }

  /// Resolve a bare language code to a device-supported BCP-47 localeId.
  String? _resolveLocaleId(String langCode) {
    if (_availableLocales.isEmpty) return null;

    final code = langCode.toLowerCase();

    // Prefer exact xx-IN match (common on Indian devices).
    for (final locale in _availableLocales) {
      if (locale.localeId.toLowerCase() == '$code-in') {
        return locale.localeId;
      }
    }

    // Fall back to first locale whose id starts with the 2-letter code.
    for (final locale in _availableLocales) {
      final id = locale.localeId.toLowerCase();
      if (id.startsWith('$code-') || id.startsWith('${code}_')) {
        return locale.localeId;
      }
    }

    // English fallbacks.
    if (code == 'en') {
      for (final locale in _availableLocales) {
        if (locale.localeId.toLowerCase() == 'en-us') {
          return locale.localeId;
        }
      }
      for (final locale in _availableLocales) {
        if (locale.localeId.toLowerCase().startsWith('en')) {
          return locale.localeId;
        }
      }
    }

    return _availableLocales.first.localeId;
  }

  Future<void> _startListening() async {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    final localeId = _resolveLocaleId(_selectedLangCode);
    if (kDebugMode) {
      print(
        '[VoiceInput] listen(localeId: "$localeId", langCode: "$_selectedLangCode")',
      );
    }

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _transcribedText = result.recognizedWords;
        });
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: localeId,
      ),
    );

    setState(() {
      _isListening = true;
      _transcribedText = '';
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });

    if (_transcribedText.isNotEmpty) {
      widget.onTextReceived(_transcribedText);
    }
  }

  @override
  void dispose() {
    _speechToText.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dropdownValue = _languageOptions.containsKey(_selectedLangCode)
        ? _selectedLangCode
        : 'en';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic),
                const SizedBox(width: 8),
                const Text(
                  'Voice Input',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: dropdownValue,
                  items: _languageOptions.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLangCode = newValue;
                      });
                    }
                  },
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_transcribedText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transcribed Text:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _transcribedText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isListening ? _stopListening : _startListening,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(_isListening ? 'Stop Listening' : 'Start Speaking'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: _isListening ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            if (!_isAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Speech recognition not available on this device',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

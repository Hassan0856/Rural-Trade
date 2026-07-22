import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputWidget extends StatefulWidget {
  final Function(String) onTextReceived;
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
  String _selectedLanguage = 'en-US';

  final Map<String, String> _languages = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Telugu': 'te-IN',
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.initialLanguage != null) {
      _selectedLanguage = widget.initialLanguage!;
    }
  }

  Future<void> _initSpeech() async {
    _isAvailable = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _transcribedText = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: _selectedLanguage,
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
                  value: _languages.entries
                      .firstWhere(
                        (entry) => entry.value == _selectedLanguage,
                        orElse: () => _languages.entries.first,
                      )
                      .key,
                  items: _languages.keys.map((String language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLanguage = _languages[newValue]!;
                      });
                    }
                  },
                  style: const TextStyle(fontSize: 14),
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
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: const Text(
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

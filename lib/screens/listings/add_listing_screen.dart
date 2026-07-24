import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/voice_input_widget.dart';
import '../../services/language_service.dart';
import '../../models/listing_enums.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final LanguageService _languageService = LanguageService();

  String _selectedCategory = 'tractor';
  String _selectedType = 'rent';
  String? _savedLanguageCode;

  final List<String> _categories = ListingEnums.categories.keys.toList();
  final List<String> _types = ListingEnums.exchangeTypes.keys.toList();

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final languageCode = await _languageService.getLanguage();
    if (mounted) {
      setState(() {
        _savedLanguageCode = languageCode;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _getLanguageLocale(String? languageCode) {
    if (languageCode == null) return null;
    switch (languageCode) {
      case 'en':
        return 'en-US';
      case 'hi':
        return 'hi-IN';
      case 'te':
        return 'te-IN';
      default:
        return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        ref.read(listingProvider.notifier).selectPhoto(bytes, image.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      ref.read(listingProvider.notifier).setLocation(
            position.latitude,
            position.longitude,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location captured successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  void _submitListing() {
    if (_formKey.currentState!.validate()) {
      final listingState = ref.read(listingProvider);
      
      if (listingState.latitude == null || listingState.longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture your location')),
        );
        return;
      }

      ref.read(listingProvider.notifier).submitListing(
            title: _titleController.text,
            description: _descriptionController.text,
            category: _selectedCategory,
            type: _selectedType,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingState = ref.watch(listingProvider);

    ref.listen<ListingState>(listingProvider, (previous, next) {
      if (next.status == ListingStatus.success) {
        context.go('/add-listing/success');
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(listingProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              VoiceInputWidget(
                onTextReceived: (text) {
                  _descriptionController.text = text;
                },
                initialLanguage: _getLanguageLocale(_savedLanguageCode),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(ListingEnums.categories[category] ?? category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Exchange Type',
                  prefixIcon: Icon(Icons.swap_horiz),
                  border: OutlineInputBorder(),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(ListingEnums.exchangeTypes[type] ?? type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (listingState.selectedPhotoBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            listingState.selectedPhotoBytes!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No photo selected', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: listingState.status == ListingStatus.uploading
                            ? null
                            : _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: listingState.status == ListingStatus.uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Choose Photo'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on),
                          const SizedBox(width: 8),
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (listingState.latitude != null &&
                              listingState.longitude != null)
                            const Icon(Icons.check_circle, color: Colors.green)
                          else
                            const Icon(Icons.error, color: Colors.red),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (listingState.latitude != null &&
                          listingState.longitude != null)
                        Text(
                          'Lat: ${listingState.latitude!.toStringAsFixed(6)}, Lng: ${listingState.longitude!.toStringAsFixed(6)}',
                          style: const TextStyle(color: Colors.green),
                        )
                      else
                        const Text(
                          'Location not captured',
                          style: TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Capture Current Location'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: listingState.status == ListingStatus.submitting ||
                        listingState.status == ListingStatus.uploading
                    ? null
                    : _submitListing,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: listingState.status == ListingStatus.submitting ||
                        listingState.status == ListingStatus.uploading
                    ? const CircularProgressIndicator()
                    : const Text('Submit Listing', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

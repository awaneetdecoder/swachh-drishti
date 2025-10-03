import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../services/secure_storage_service.dart';

/// A screen for users to report a garbage-related issue.
///
/// This screen allows users to fetch their current location, upload an image,
/// describe the problem, and submit the report to the backend. It includes
/// logic for handling permissions, image picking, and secure, authenticated API calls.
class GarbageReporterScreen extends StatefulWidget {
  const GarbageReporterScreen({super.key});
  @override
  State<GarbageReporterScreen> createState() => _GarbageReporterScreenState();
}

class _GarbageReporterScreenState extends State<GarbageReporterScreen> {
  // API endpoint from our central configuration.
  final String _reportUrl = ApiConfig.reports;

  // Form key and controllers for managing the form's state.
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _problemController = TextEditingController();

  // State variables to hold the selected image and manage loading indicators.
  File? _imageFile;
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  /// Fetches the device's current GPS location and converts it to a readable address.
  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      // Check and request location permissions.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showError("Location permissions are permanently denied. Please enable them in your device settings.");
        return;
      }
      if (permission == LocationPermission.denied) {
        _showError("Location permissions are denied.");
        return;
      }

      // Get the current position.
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      // Convert coordinates into an address (reverse geocoding).
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final address = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
        _locationController.text = address;
      }
    } catch (e) {
      _showError("Failed to get location: $e");
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  /// Allows the user to pick an image from their gallery or camera.
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    // Pick an image, with constraints to reduce file size for faster uploads.
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  /// Handles the entire report submission process.
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showError("Please upload an image of the dump.");
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      // --- THIS IS THE "SECURITY GUARD" CHECK ---
      // 1. Get the saved ID card (token) from the secure wallet.
      final String? token = await SecureStorageService.getToken();
      if (token == null || token.isEmpty) {
        _showError("Authentication error. Please log out and log back in.");
        setState(() => _isSubmitting = false);
        return;
      }
      // --- END OF CHECK ---

      // A multipart request is needed to send both text fields and an image file.
      var request = http.MultipartRequest('POST', Uri.parse(_reportUrl));

      // 2. Show the ID card to the backend's security guard (the 'protect' middleware).
      request.headers['Authorization'] = 'Bearer $token';

      // 3. Add the report details as text fields.
      // These keys must match what the backend expects.
      request.fields['address'] = _locationController.text;
      request.fields['description'] = _problemController.text;
      request.fields['latitude'] = '0.0'; // Placeholder, would be replaced by real coordinates
      request.fields['longitude'] = '0.0'; // Placeholder

      // 4. Add the image file.
      // The key 'image' must match what the backend's Multer middleware expects.
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      // 5. Send the request and wait for the response.
      var response = await request.send();

      if (response.statusCode == 201) { // 201 Created
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody);
        _showSuccessDialog(responseData['analysisResult'] ?? 'No analysis result received.');
      } else {
        final errorBody = await response.stream.bytesToString();
        _showError("Failed to submit report: $errorBody");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Displays a red error message at the bottom of the screen.
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }
  
  /// Displays a success dialog with the AI analysis result.
  void _showSuccessDialog(String analysisResult) {
     showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Report Submitted Successfully'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text('Your report has been received and is pending review.', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    const Text('AI Verification:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(analysisResult),
                    const SizedBox(height: 16),
                    Image.file(_imageFile!),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Reset the form for the next report.
                    _formKey.currentState?.reset();
                    setState(() {
                      _imageFile = null;
                      _locationController.clear();
                      _problemController.clear();
                    });
                  },
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Report an Issue', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const Text('1. Pinpoint the Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Address or Landmark', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter a location.' : null,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                icon: _isFetchingLocation ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
                label: const Text('Get Current Location'),
              ),
              const SizedBox(height: 24),
              const Text('2. Upload an Image of the Dump', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: _imageFile != null ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(_imageFile!, fit: BoxFit.cover)) : const Center(child: Text('No Image Selected')),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera')),
                  ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery')),
                ],
              ),
              const SizedBox(height: 24),
              const Text('3. Describe the problem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _problemController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'e.g., Garbage pile has not been cleared for a week.', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please describe the problem.' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isSubmitting ? null : _submitReport,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Report', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


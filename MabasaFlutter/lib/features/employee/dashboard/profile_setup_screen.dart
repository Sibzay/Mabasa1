// ============================================
// FILE 2: profile_setup_screen.dart (NEW FILE)
// Location: lib/features/employee/presentation/screens/profile_setup_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/services/api_client.dart';
import 'package:dio/dio.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  // Form controllers
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();

  // File data
  File? _profileImage;
  File? _cvFile;
  String? _cvFileName;

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> _pickCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        _cvFile = File(result.files.single.path!);
        _cvFileName = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFB4E4FF),
              const Color(0xFF95D5FF),
              const Color(0xFF7EC8FF).withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step ${_currentStep + 1} of 3',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressIndicator(),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: _buildStepContent(),
                  ),
                ),
              ),

              // Navigation Buttons
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7EC8FF)),
                            foregroundColor: const Color(0xFF7EC8FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: _currentStep == 0 ? 1 : 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7EC8FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _currentStep == 2 ? 'Complete' : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: index <= _currentStep
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildProfessionalInfoStep();
      case 2:
        return _buildDocumentsStep();
      default:
        return Container();
    }
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Profile Image
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF7EC8FF).withOpacity(0.1),
                shape: BoxShape.circle,
                image: _profileImage != null
                    ? DecorationImage(
                        image: FileImage(_profileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImage == null
                  ? const Icon(
                      Icons.add_a_photo_rounded,
                      size: 40,
                      color: Color(0xFF7EC8FF),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add Profile Photo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7EC8FF),
            ),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter phone number';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.home_rounded,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter address';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _cityController,
            label: 'City',
            icon: Icons.location_city_rounded,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter city';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _bioController,
            label: 'Bio / About You',
            icon: Icons.person_rounded,
            maxLines: 4,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter a brief bio';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildTextField(
            controller: _experienceController,
            label: 'Work Experience',
            icon: Icons.work_rounded,
            maxLines: 5,
            hint: 'List your previous work experience...',
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter work experience';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _educationController,
            label: 'Education',
            icon: Icons.school_rounded,
            maxLines: 4,
            hint: 'List your educational qualifications...',
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter education';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _skillsController,
            label: 'Skills',
            icon: Icons.star_rounded,
            maxLines: 4,
            hint: 'List your key skills (comma separated)...',
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter your skills';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            'Upload Your CV/Resume',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps employers understand your background',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // CV Upload
          GestureDetector(
            onTap: _pickCV,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF7EC8FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF7EC8FF).withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _cvFile != null
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    size: 64,
                    color: const Color(0xFF7EC8FF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _cvFile != null ? _cvFileName! : 'Tap to upload CV',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7EC8FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDF, DOC, or DOCX',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF7EC8FF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF7EC8FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep < 2) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _currentStep++);
      }
    } else {
      // Final step - submit profile
      if (_cvFile == null) {
        setState(() => _error = 'Please upload your CV');
        return;
      }

      await _submitProfile();
    }
  }

  Future<void> _submitProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = await ApiClient().authed();

      // Create FormData for file upload
      final formData = FormData.fromMap({
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
        'experience': _experienceController.text.trim(),
        'education': _educationController.text.trim(),
        'skills': _skillsController.text.trim(),
        if (_profileImage != null)
          'profile_image': await MultipartFile.fromFile(_profileImage!.path),
        if (_cvFile != null) 'cv': await MultipartFile.fromFile(_cvFile!.path),
      });

      await dio.post('/api/auth/profile/setup/', data: formData);

      if (mounted) {
        // Navigate to dashboard
        Navigator.of(context).pushReplacementNamed('/dashboard/employee');
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?.toString() ?? 'Failed to save profile';
      });
    } catch (e) {
      setState(() => _error = 'An error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

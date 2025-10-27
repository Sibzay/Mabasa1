// ============================================
// FILE 2: profile_setup_screen.dart (NEW FILE)
// Location: lib/features/employee/presentation/screens/profile_setup_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final _yearsExperienceController = TextEditingController();

  // Education and Experience lists
  List<Map<String, dynamic>> _educationList = [];
  List<Map<String, dynamic>> _experienceList = [];

  // File data
  File? _profileImage;
  File? _cvFile;
  String? _cvFileName;
  String? _cvUrl;
  bool _useUrl = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    _yearsExperienceController.dispose();
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select CV Option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload File'),
              subtitle: const Text('Select PDF, DOC, or DOCX from device'),
              onTap: () async {
                Navigator.of(context).pop();
                await _pickCVFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Use URL'),
              subtitle: const Text('Enter a link to your CV'),
              onTap: () async {
                Navigator.of(context).pop();
                await _enterCVUrl();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCVFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _cvFile = File(result.files.single.path!);
          _cvFileName = result.files.single.name;
          _cvUrl = null;
          _useUrl = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick file')),
      );
    }
  }

  Future<void> _enterCVUrl() async {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter CV URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/my-cv.pdf',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                setState(() {
                  _cvUrl = url;
                  _cvFileName = url;
                  _cvFile = null;
                  _useUrl = true;
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              const Color(0xFF1E40AF),
              const Color(0xFF1D4ED8),
              const Color(0xFF1E3A8A).withOpacity(0.9),
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
                            side: const BorderSide(color: Color(0xFF1E3A8A)),
                            foregroundColor: const Color(0xFF1E3A8A),
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
                          backgroundColor: const Color(0xFF1E3A8A),
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
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
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
                      color: Color(0xFF1E3A8A),
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
              color: Color(0xFF1E3A8A),
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
            controller: _yearsExperienceController,
            label: 'Years of Experience',
            icon: Icons.timeline_rounded,
            keyboardType: TextInputType.number,
            hint: 'Enter years of professional experience',
            validator: (value) {
              if (value?.isEmpty ?? true)
                return 'Please enter years of experience';
              if (int.tryParse(value!) == null)
                return 'Please enter a valid number';
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
          const SizedBox(height: 24),
          _buildSectionTitle('Education'),
          const SizedBox(height: 16),
          _buildEducationList(),
          const SizedBox(height: 24),
          _buildSectionTitle('Work Experience'),
          const SizedBox(height: 16),
          _buildExperienceList(),
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
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    (_cvFile != null || _cvUrl != null)
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    size: 64,
                    color: const Color(0xFF1E3A8A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (_cvFile != null || _cvUrl != null)
                        ? (_cvFileName ?? 'CV Selected')
                        : 'Tap to select CV',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cvFile != null
                        ? 'File selected'
                        : _cvUrl != null
                            ? 'URL provided'
                            : 'PDF, DOC, DOCX or URL',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
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
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
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
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
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
      if (_cvFile == null && _cvUrl == null) {
        setState(() => _error = 'Please upload your CV or provide a URL');
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
        'years_experience': _yearsExperienceController.text.trim(),
        'education_list': _educationList,
        'experience_list': _experienceList,
        if (_profileImage != null)
          'profile_image': await MultipartFile.fromFile(_profileImage!.path),
        if (_cvFile != null) 'cv': await MultipartFile.fromFile(_cvFile!.path),
        if (_cvUrl != null && _cvUrl!.isNotEmpty) 'cv_url': _cvUrl,
      });

      await dio.post('/api/auth/profile/setup/', data: formData);

      if (mounted) {
        // Navigate to dashboard
        context.go('/dashboard/employee');
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E86AB),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _addEducationOrExperience(title),
          icon: const Icon(Icons.add, color: Color(0xFF2E86AB)),
          tooltip: 'Add $title',
        ),
      ],
    );
  }

  Widget _buildEducationList() {
    if (_educationList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            'No education entries yet. Tap + to add.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: _educationList.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> education = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(education['qualification'] ?? ''),
            subtitle: Text(education['institution'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _educationList.removeAt(index)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExperienceList() {
    if (_experienceList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            'No experience entries yet. Tap + to add.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: _experienceList.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> experience = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(experience['role'] ?? ''),
            subtitle: Text(
                '${experience['company'] ?? ''} (${experience['start']} - ${experience['end']})'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _experienceList.removeAt(index)),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _addEducationOrExperience(String type) {
    showDialog(
      context: context,
      builder: (context) => _buildAddDialog(type),
    );
  }

  Widget _buildAddDialog(String type) {
    final institutionController = TextEditingController();
    final qualificationController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();
    final descriptionController = TextEditingController();

    return AlertDialog(
      title: Text('Add $type'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == 'Education') ...[
              TextField(
                controller: institutionController,
                decoration: const InputDecoration(labelText: 'Institution'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qualificationController,
                decoration: const InputDecoration(labelText: 'Qualification'),
              ),
            ] else ...[
              TextField(
                controller: institutionController,
                decoration: const InputDecoration(labelText: 'Company'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qualificationController,
                decoration: const InputDecoration(labelText: 'Role/Position'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: startController,
              decoration: const InputDecoration(labelText: 'Start Date (YYYY)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: endController,
              decoration: const InputDecoration(
                  labelText: 'End Date (YYYY) or "Present"'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (type == 'Education') {
              _educationList.add({
                'institution': institutionController.text,
                'qualification': qualificationController.text,
                'start': startController.text,
                'end': endController.text,
              });
            } else {
              _experienceList.add({
                'company': institutionController.text,
                'role': qualificationController.text,
                'start': startController.text,
                'end': endController.text,
                'description': descriptionController.text,
              });
            }
            setState(() {});
            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

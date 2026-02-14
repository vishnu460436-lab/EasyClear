import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'success_screen.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedCategory;
  final List<Map<String, String>> _categories = [
    {'value': 'pwd', 'label': 'Road Issue / PWD'},
    {'value': 'water', 'label': 'Water Authority'},
    {'value': 'kseb', 'label': 'Electricity / KSEB'},
    {'value': 'police', 'label': 'Police Station'},
    {'value': 'other', 'label': 'Other'},
  ];

  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.submitReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        address: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        imageFile: _image!,
      );

      if (!mounted) return;

      // Navigate to SuccessScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SuccessScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const secondaryColor = Color(0xFF3B82F6);
    const backgroundColor = Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Report Issue',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Issue Title
                              _buildLabel('Issue Title:'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _titleController,
                                hintText: 'Enter title',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Category
                              _buildLabel('Category:'),
                              const SizedBox(height: 8),
                              InputDecorator(
                                decoration:
                                    _inputDecoration(
                                      hintText: 'Select Category',
                                    ).copyWith(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                    ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isDense: true,
                                    hint: Text(
                                      'Select Category',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    items: _categories.map((category) {
                                      return DropdownMenuItem<String>(
                                        value: category['value'],
                                        child: Text(category['label']!),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCategory = newValue;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: secondaryColor,
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Description
                              _buildLabel('Description:'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _descriptionController,
                                hintText: 'Describe the issue...',
                                maxLines: 4,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please provide a description';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Location
                              _buildLabel('Location Address:'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _locationController,
                                hintText: 'Enter address',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Upload Photo
                              _buildLabel('Upload Photo:'),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () =>
                                    _showImageSourceActionSheet(context),
                                child: Container(
                                  width: double.infinity,
                                  height: 200,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: _image != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            _image!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.cloud_upload,
                                              size: 48,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Tap to upload photo',
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF64748B),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitReport,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Text(
                                    'Submit Report',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(
    String text, {
    double fontSize = 16,
    Color color = const Color(0xFF334155),
  }) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildTextField({
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextEditingController? controller,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: _inputDecoration(hintText: hintText),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
    );
  }
}

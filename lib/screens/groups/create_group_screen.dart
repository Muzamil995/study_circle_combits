import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_circle/models/study_group_model.dart';
import 'package:study_circle/providers/auth_provider.dart' as app_auth;
import 'package:study_circle/services/firestore_service.dart';
import 'package:study_circle/theme/app_colors.dart';

class CreateGroupScreen extends StatefulWidget {
  final StudyGroupModel? group; // null for create, non-null for edit

  const CreateGroupScreen({super.key, this.group});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Form controllers
  late TextEditingController _groupNameController;
  late TextEditingController _courseNameController;
  late TextEditingController _courseCodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _scheduleController;
  late TextEditingController _locationController;
  late TextEditingController _maxMembersController;
  late TextEditingController _topicController;

  bool _isPublic = true;
  List<String> _topics = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing values if editing
    _groupNameController = TextEditingController(text: widget.group?.groupName ?? '');
    _courseNameController = TextEditingController(text: widget.group?.courseName ?? '');
    _courseCodeController = TextEditingController(text: widget.group?.courseCode ?? '');
    _descriptionController = TextEditingController(text: widget.group?.description ?? '');
    _scheduleController = TextEditingController(text: widget.group?.schedule ?? '');
    _locationController = TextEditingController(text: widget.group?.location ?? '');
    _maxMembersController = TextEditingController(
      text: widget.group?.maxMembers.toString() ?? '10',
    );
    _topicController = TextEditingController();
    
    _isPublic = widget.group?.isPublic ?? true;
    _topics = List.from(widget.group?.topics ?? []);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _descriptionController.dispose();
    _scheduleController.dispose();
    _locationController.dispose();
    _maxMembersController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.group != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Group' : 'Create Study Group',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Basic Information'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _groupNameController,
              label: 'Group Name',
              hint: 'e.g., Data Structures Study Group',
              icon: Icons.group,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a group name';
                }
                if (value.length < 3) {
                  return 'Group name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _courseCodeController,
                    label: 'Course Code',
                    hint: 'e.g., CS101',
                    icon: Icons.code,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _courseNameController,
                    label: 'Course Name',
                    hint: 'e.g., Introduction to Computer Science',
                    icon: Icons.school,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe what this group is about...',
              icon: Icons.description,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Schedule & Location'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _scheduleController,
              label: 'Schedule',
              hint: 'e.g., Mondays and Wednesdays, 3-5 PM',
              icon: Icons.schedule,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a schedule';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'e.g., Library Room 301 or Online (Zoom)',
              icon: Icons.location_on,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Topics'),
            const SizedBox(height: 16),
            _buildTopicsSection(),
            const SizedBox(height: 24),
            _buildSectionHeader('Settings'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _maxMembersController,
              label: 'Maximum Members',
              hint: '10',
              icon: Icons.people,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                final num = int.tryParse(value);
                if (num == null || num < 2 || num > 50) {
                  return 'Must be between 2 and 50';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildVisibilityToggle(),
            const SizedBox(height: 32),
            _buildSubmitButton(isEditing),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.gray800,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.gray50,
      ),
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Widget _buildTopicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _topicController,
                decoration: InputDecoration(
                  hintText: 'Enter a topic (e.g., Arrays, Sorting)',
                  prefixIcon: const Icon(Icons.topic),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.gray50,
                ),
                onSubmitted: (_) => _addTopic(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addTopic,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (_topics.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topics.map((topic) {
              return Chip(
                label: Text(topic),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _topics.remove(topic);
                  });
                },
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: AppColors.primary),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Icon(
            _isPublic ? Icons.public : Icons.lock,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Public Group' : 'Private Group',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPublic
                      ? 'Anyone can find and join this group'
                      : 'Only invited members can join',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isEditing ? 'Update Group' : 'Create Group',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _addTopic() {
    final topic = _topicController.text.trim();
    if (topic.isNotEmpty && !_topics.contains(topic)) {
      setState(() {
        _topics.add(topic);
        _topicController.clear();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<app_auth.AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to create a group');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.group != null;
      
      if (isEditing) {
        // Update existing group
        final updatedGroup = widget.group!.copyWith(
          groupName: _groupNameController.text.trim(),
          courseName: _courseNameController.text.trim(),
          courseCode: _courseCodeController.text.trim(),
          description: _descriptionController.text.trim(),
          schedule: _scheduleController.text.trim(),
          location: _locationController.text.trim(),
          maxMembers: int.parse(_maxMembersController.text),
          isPublic: _isPublic,
          topics: _topics,
          updatedAt: DateTime.now(),
        );

        await _firestoreService.updateStudyGroup(updatedGroup);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new group
        final newGroup = StudyGroupModel(
          id: '', // Firestore will generate
          groupName: _groupNameController.text.trim(),
          courseName: _courseNameController.text.trim(),
          courseCode: _courseCodeController.text.trim(),
          description: _descriptionController.text.trim(),
          schedule: _scheduleController.text.trim(),
          location: _locationController.text.trim(),
          maxMembers: int.parse(_maxMembersController.text),
          isPublic: _isPublic,
          topics: _topics,
          creatorId: currentUser.uid,
          creatorName: currentUser.name,
          memberIds: [currentUser.uid], // Creator is first member
          memberCount: 1,
        );

        await _firestoreService.createStudyGroup(newGroup);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back and optionally open the new group
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save group: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

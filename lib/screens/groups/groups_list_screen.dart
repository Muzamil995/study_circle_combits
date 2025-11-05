import 'package:flutter/material.dart';
import 'package:study_circle/models/study_group_model.dart';
import 'package:study_circle/services/firestore_service.dart';
import 'package:study_circle/theme/app_colors.dart';
import 'package:study_circle/utils/constants.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedDepartment;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Study Groups',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Groups'),
            Tab(text: 'My Groups'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllGroupsTab(),
                _buildMyGroupsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: AppColors.gray200),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search groups by name or course code...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.gray50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Departments'),
                  selected: _selectedDepartment == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDepartment = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...AppConstants.departments.take(5).map((dept) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(dept),
                      selected: _selectedDepartment == dept,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDepartment = selected ? dept : null;
                        });
                      },
                    ),
                  );
                }),
                // More button
                ActionChip(
                  label: const Text('More...'),
                  avatar: const Icon(Icons.filter_list, size: 18),
                  onPressed: () => _showDepartmentFilter(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllGroupsTab() {
    return StreamBuilder<List<StudyGroupModel>>(
      stream: _firestoreService.getPublicGroups(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading groups: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data ?? [];
        
        // Apply filters
        final filteredGroups = _filterGroups(groups);

        if (filteredGroups.isEmpty) {
          return _buildEmptyState(
            icon: Icons.group_off,
            title: 'No groups found',
            message: _searchQuery.isNotEmpty || _selectedDepartment != null
                ? 'Try adjusting your filters'
                : 'Be the first to create a study group!',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredGroups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _GroupCard(group: filteredGroups[index]);
          },
        );
      },
    );
  }

  Widget _buildMyGroupsTab() {
    // TODO: Get current user ID from AuthProvider
    // For now, show empty state
    return _buildEmptyState(
      icon: Icons.groups,
      title: 'My Groups',
      message: 'Groups you join or create will appear here',
    );
  }

  List<StudyGroupModel> _filterGroups(List<StudyGroupModel> groups) {
    var filtered = groups;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((group) {
        return group.name.toLowerCase().contains(query) ||
            group.courseCode.toLowerCase().contains(query) ||
            group.description.toLowerCase().contains(query);
      }).toList();
    }

    // Apply department filter
    if (_selectedDepartment != null) {
      filtered = filtered.where((group) {
        return group.courseName.contains(_selectedDepartment!);
      }).toList();
    }

    return filtered;
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter by Department',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDepartment = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        RadioListTile<String?>(
                          title: const Text('All Departments'),
                          value: null,
                          groupValue: _selectedDepartment,
                          onChanged: (value) {
                            setState(() {
                              _selectedDepartment = value;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        ...AppConstants.departments.map((dept) {
                          return RadioListTile<String>(
                            title: Text(dept),
                            value: dept,
                            groupValue: _selectedDepartment,
                            onChanged: (value) {
                              setState(() {
                                _selectedDepartment = value;
                              });
                              Navigator.pop(context);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Group Card Widget
class _GroupCard extends StatelessWidget {
  final StudyGroupModel group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.gray200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/group-details',
            arguments: group.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.courseCode,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (group.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  group.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.people,
                    label: '${group.memberIds.length}/${group.maxMembers} members',
                  ),
                  _InfoChip(
                    icon: Icons.school,
                    label: group.courseName,
                  ),
                  if (group.isPublic)
                    _InfoChip(
                      icon: Icons.public,
                      label: 'Public',
                      color: AppColors.success,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (group.memberIds.length >= group.maxMembers) {
      return AppColors.error;
    } else if (group.memberIds.length >= (group.maxMembers * 0.8)) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  String _getStatusText() {
    if (group.memberIds.length >= group.maxMembers) {
      return 'Full';
    } else if (group.memberIds.length >= (group.maxMembers * 0.8)) {
      return 'Almost Full';
    }
    return 'Open';
  }
}

// Info Chip Widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.gray600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

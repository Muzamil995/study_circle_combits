import 'package:flutter/material.dart';
import 'package:study_circle/theme/app_colors.dart';

class SessionsListScreen extends StatelessWidget {
  const SessionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text(
              'Study Sessions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filter coming soon!')),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Upcoming Sessions'),
                  const SizedBox(height: 16),
                  _buildEmptyState(
                    icon: Icons.event_busy,
                    title: 'No Upcoming Sessions',
                    message: 'Join a study group to see upcoming sessions here',
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Past Sessions'),
                  const SizedBox(height: 16),
                  _buildEmptyState(
                    icon: Icons.history,
                    title: 'No Past Sessions',
                    message: 'Your attended sessions will appear here',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create session coming soon!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Schedule Session'),
        backgroundColor: AppColors.primary,
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 64, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
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
}

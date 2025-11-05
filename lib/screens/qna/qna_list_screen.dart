import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_circle/models/question_model.dart';
import 'package:study_circle/models/study_group_model.dart';
import 'package:study_circle/providers/auth_provider.dart';
import 'package:study_circle/services/firestore_service.dart';
import 'package:study_circle/theme/app_colors.dart';
import 'package:study_circle/utils/helpers.dart';

class QnaListScreen extends StatefulWidget {
  final StudyGroupModel group;

  const QnaListScreen({super.key, required this.group});

  @override
  State<QnaListScreen> createState() => _QnaListScreenState();
}

class _QnaListScreenState extends State<QnaListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filterOption = 'all'; // all, resolved, unresolved

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userModel?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Q&A'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterOption = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Questions'),
              ),
              const PopupMenuItem(
                value: 'unresolved',
                child: Text('Unresolved'),
              ),
              const PopupMenuItem(
                value: 'resolved',
                child: Text('Resolved'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<QuestionModel>>(
        stream: _firestoreService.getGroupQuestions(widget.group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<QuestionModel> questions = snapshot.data ?? [];

          // Apply filter
          if (_filterOption == 'resolved') {
            questions = questions.where((q) => q.isResolved).toList();
          } else if (_filterOption == 'unresolved') {
            questions = questions.where((q) => !q.isResolved).toList();
          }

          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.question_answer_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to ask a question!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(questions[index], currentUserId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/ask-question',
            arguments: widget.group,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Ask Question'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, String currentUserId) {
    final voteScore = question.voteScore;
    final hasUpvoted = question.hasUserUpvoted(currentUserId);
    final hasDownvoted = question.hasUserDownvoted(currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/question-details',
            arguments: question,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with resolved badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (question.isResolved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Resolved',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                question.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              // Footer with votes, answers, and author
              Row(
                children: [
                  // Upvote button
                  InkWell(
                    onTap: () => _toggleUpvote(question.id, currentUserId),
                    child: Icon(
                      hasUpvoted
                          ? Icons.arrow_upward
                          : Icons.arrow_upward_outlined,
                      size: 20,
                      color: hasUpvoted ? AppColors.primary : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Vote score
                  Text(
                    voteScore.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: voteScore > 0
                          ? AppColors.primary
                          : voteScore < 0
                              ? Colors.red
                              : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Downvote button
                  InkWell(
                    onTap: () => _toggleDownvote(question.id, currentUserId),
                    child: Icon(
                      hasDownvoted
                          ? Icons.arrow_downward
                          : Icons.arrow_downward_outlined,
                      size: 20,
                      color: hasDownvoted ? Colors.red : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Answer count
                  Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${question.answerCount} ${question.answerCount == 1 ? 'answer' : 'answers'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // Author and time
                  Text(
                    'by ${question.askedByName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '• ${Helpers.getRelativeTime(question.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleUpvote(String questionId, String userId) async {
    try {
      await _firestoreService.toggleQuestionUpvote(questionId, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _toggleDownvote(String questionId, String userId) async {
    try {
      await _firestoreService.toggleQuestionDownvote(questionId, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}

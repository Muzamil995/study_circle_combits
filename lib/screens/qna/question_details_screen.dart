import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_circle/models/answer_model.dart';
import 'package:study_circle/models/question_model.dart';
import 'package:study_circle/providers/auth_provider.dart';
import 'package:study_circle/services/firestore_service.dart';
import 'package:study_circle/theme/app_colors.dart';
import 'package:study_circle/utils/helpers.dart';

class QuestionDetailsScreen extends StatefulWidget {
  final QuestionModel question;

  const QuestionDetailsScreen({super.key, required this.question});

  @override
  State<QuestionDetailsScreen> createState() => _QuestionDetailsScreenState();
}

class _QuestionDetailsScreenState extends State<QuestionDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _answerController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userModel?.uid ?? '';
    final isQuestionOwner = widget.question.askedBy == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        actions: [
          if (isQuestionOwner)
            IconButton(
              icon: Icon(
                widget.question.isResolved
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: widget.question.isResolved ? Colors.green : null,
              ),
              tooltip: widget.question.isResolved
                  ? 'Mark as unresolved'
                  : 'Mark as resolved',
              onPressed: () => _toggleResolved(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question section
                  _buildQuestionSection(currentUserId),
                  const Divider(height: 1, thickness: 1),
                  // Answers section
                  _buildAnswersSection(currentUserId, isQuestionOwner),
                ],
              ),
            ),
          ),
          // Answer input
          _buildAnswerInput(authProvider),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(String currentUserId) {
    final voteScore = widget.question.voteScore;
    final hasUpvoted = widget.question.hasUserUpvoted(currentUserId);
    final hasDownvoted = widget.question.hasUserDownvoted(currentUserId);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with resolved badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.question.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.question.isResolved)
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
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
          const SizedBox(height: 12),
          // Description
          Text(
            widget.question.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Footer with votes and author
          Row(
            children: [
              // Vote section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _toggleQuestionUpvote(currentUserId),
                      child: Icon(
                        hasUpvoted
                            ? Icons.arrow_upward
                            : Icons.arrow_upward_outlined,
                        size: 20,
                        color: hasUpvoted ? AppColors.primary : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      voteScore.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: voteScore > 0
                            ? AppColors.primary
                            : voteScore < 0
                                ? Colors.red
                                : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _toggleQuestionDownvote(currentUserId),
                      child: Icon(
                        hasDownvoted
                            ? Icons.arrow_downward
                            : Icons.arrow_downward_outlined,
                        size: 20,
                        color: hasDownvoted ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Author
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Asked by ${widget.question.askedByName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    Helpers.getRelativeTime(widget.question.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersSection(String currentUserId, bool isQuestionOwner) {
    return StreamBuilder<List<AnswerModel>>(
      stream: _firestoreService.getQuestionAnswers(widget.question.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final answers = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${answers.length} ${answers.length == 1 ? 'Answer' : 'Answers'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (answers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No answers yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to answer!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...answers.map((answer) =>
                  _buildAnswerCard(answer, currentUserId, isQuestionOwner)),
          ],
        );
      },
    );
  }

  Widget _buildAnswerCard(
      AnswerModel answer, String currentUserId, bool isQuestionOwner) {
    final voteScore = answer.voteScore;
    final hasUpvoted = answer.hasUserUpvoted(currentUserId);
    final hasDownvoted = answer.hasUserDownvoted(currentUserId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answer.isAccepted ? Colors.green.withValues(alpha: 0.05) : null,
        border: Border(
          left: BorderSide(
            color: answer.isAccepted ? Colors.green : Colors.transparent,
            width: 4,
          ),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accepted badge
          if (answer.isAccepted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Accepted Answer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          // Answer content
          Text(
            answer.content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Footer
          Row(
            children: [
              // Vote section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _toggleAnswerUpvote(answer.id, currentUserId),
                      child: Icon(
                        hasUpvoted
                            ? Icons.arrow_upward
                            : Icons.arrow_upward_outlined,
                        size: 18,
                        color: hasUpvoted ? AppColors.primary : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      voteScore.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: voteScore > 0
                            ? AppColors.primary
                            : voteScore < 0
                                ? Colors.red
                                : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _toggleAnswerDownvote(answer.id, currentUserId),
                      child: Icon(
                        hasDownvoted
                            ? Icons.arrow_downward
                            : Icons.arrow_downward_outlined,
                        size: 18,
                        color: hasDownvoted ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Accept button (only for question owner)
              if (isQuestionOwner && !answer.isAccepted)
                TextButton.icon(
                  onPressed: () => _acceptAnswer(answer.id),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Accept'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ),
              const Spacer(),
              // Author
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    answer.answeredByName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    Helpers.getRelativeTime(answer.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(AuthProvider authProvider) {
    if (authProvider.userModel == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _answerController,
              decoration: InputDecoration(
                hintText: 'Write your answer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isSubmitting ? null : _submitAnswer,
            backgroundColor: AppColors.primary,
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswer() async {
    final content = _answerController.text.trim();
    if (content.isEmpty) return;

    if (content.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Answer must be at least 10 characters long')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userModel;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _firestoreService.createAnswer(
        questionId: widget.question.id,
        groupId: widget.question.groupId,
        content: content,
        userId: currentUser.uid,
        userName: currentUser.name,
      );

      _answerController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _toggleQuestionUpvote(String userId) async {
    try {
      await _firestoreService.toggleQuestionUpvote(widget.question.id, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _toggleQuestionDownvote(String userId) async {
    try {
      await _firestoreService.toggleQuestionDownvote(
          widget.question.id, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _toggleAnswerUpvote(String answerId, String userId) async {
    try {
      await _firestoreService.toggleAnswerUpvote(answerId, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _toggleAnswerDownvote(String answerId, String userId) async {
    try {
      await _firestoreService.toggleAnswerDownvote(answerId, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _acceptAnswer(String answerId) async {
    try {
      await _firestoreService.acceptAnswer(widget.question.id, answerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer accepted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _toggleResolved() async {
    try {
      await _firestoreService.markQuestionAsResolved(
        widget.question.id,
        !widget.question.isResolved,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.question.isResolved
                  ? 'Question marked as unresolved'
                  : 'Question marked as resolved',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}

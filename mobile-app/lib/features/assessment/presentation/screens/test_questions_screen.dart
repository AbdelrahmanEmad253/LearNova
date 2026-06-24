import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/features/assessment/presentation/providers/assessment_providers.dart';
import 'package:learnova/features/assessment/presentation/providers/perk_providers.dart';
import 'package:learnova/features/assessment/presentation/screens/test_complete_screen.dart';
import 'package:learnova/features/assessment/presentation/widgets/perk_deck_overlay.dart';
import 'package:learnova/features/assessment/presentation/widgets/perk_cast_effect.dart';
import 'package:learnova/features/assessment/domain/entities/exam_perk.dart';
import 'package:learnova/core/constants/app_assets.dart';

class TestQuestionsScreen extends ConsumerStatefulWidget {
  final int testIndex;
  final String? diagnosticTestTypeId;
  final String? quizId;
  final String? challengeId;
  final bool isLevelExam;
  final int totalQuestions;
  final bool returnToHomeOnFinish;
  final String? completionTitle;
  final String? sourceNodeId;
  final int passThreshold;
  final List<Map<String, dynamic>>? initialQuestions;
  final String? difficulty;

  const TestQuestionsScreen({
    super.key,
    required this.testIndex,
    this.initialQuestions,
    this.quizId,
    this.challengeId,
    this.isLevelExam = false,
    this.diagnosticTestTypeId,
    this.totalQuestions = 5,
    this.passThreshold = 70,
    this.returnToHomeOnFinish = false,
    this.completionTitle,
    this.sourceNodeId,
    this.difficulty,
  });

  @override
  ConsumerState<TestQuestionsScreen> createState() =>
      _TestQuestionsScreenState();
}

class _TestQuestionsScreenState extends ConsumerState<TestQuestionsScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  final List<Map<String, dynamic>> _userRawAnswers = <Map<String, dynamic>>[];
  bool _isLoadingQuestions = false;
  List<Map<String, dynamic>> _dynamicQuestions = <Map<String, dynamic>>[];
  late final String _diagnosticTestTypeId;
  String? _lastSubmitError;

  /// Tracks which perk just fired so we can show the cast effect overlay.
  ExamPerk? _activeCastEffect;

  final TextEditingController _essayController = TextEditingController();

  @override
  void dispose() {
    _essayController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final diagnosticDS = ref.read(diagnosticRemoteDataSourceProvider);
    _diagnosticTestTypeId = widget.diagnosticTestTypeId ??
        diagnosticDS.diagnosticTypeIdForTestIndex(widget.testIndex);

    final hasInitialQuestions =
        widget.initialQuestions != null && widget.initialQuestions!.isNotEmpty;
    if (hasInitialQuestions) {
      _dynamicQuestions = List<Map<String, dynamic>>.from(
        widget.initialQuestions!,
      );
      _applyDiagnosticCache(_dynamicQuestions.length);
    } else if (widget.quizId != null && widget.quizId!.isNotEmpty) {
      // Module exam flow — fetch by quiz_id
      _loadExamQuestions();
    } else if (!widget.returnToHomeOnFinish) {
      _loadDynamicQuestions();
    }
  }

  void _applyDiagnosticCache(int totalQuestions) {
    if (_isExamFlow || _isChallengeFlow || _isLevelExamFlow) return;

    final localDS = ref.read(assessmentLocalDataSourceProvider);
    final cachedAnswers = localDS.getCachedDiagnosticAnswers(_diagnosticTestTypeId);
    
    if (cachedAnswers != null && cachedAnswers.isNotEmpty) {
      _userRawAnswers.clear();
      _userRawAnswers.addAll(cachedAnswers);
      final newCurrentIndex = _userRawAnswers.length;
      _currentQuestionIndex = newCurrentIndex < totalQuestions ? newCurrentIndex : (totalQuestions > 0 ? totalQuestions - 1 : 0);
    }
  }

  Future<void> _loadDynamicQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
    });

    final diagnosticDS = ref.read(diagnosticRemoteDataSourceProvider);
    final questions =
        await diagnosticDS.fetchDiagnosticQuestions(_diagnosticTestTypeId);

    if (!mounted) {
      return;
    }

    // Check for cached answers
    _applyDiagnosticCache(questions.length);

    setState(() {
      _dynamicQuestions = questions;
      _isLoadingQuestions = false;
    });
  }

  Future<void> _loadExamQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
    });

    try {
      final diagnosticDS = ref.read(diagnosticRemoteDataSourceProvider);
      
      final List<Map<String, dynamic>> questions;
      
      final rawDiff = (widget.difficulty ?? 'easy').toLowerCase();
      final mappedDiff = rawDiff == 'medium' ? 'mid' : rawDiff;
      
      if (_isLevelExamFlow) {
        questions = await diagnosticDS.fetchLevelExamQuestions(widget.quizId!, difficulty: mappedDiff);
      } else {
        questions = await diagnosticDS.fetchExamQuestions(
          widget.quizId!,
          difficulty: mappedDiff,
        );
      }

      if (!mounted) return;

      setState(() {
        _dynamicQuestions = questions;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingQuestions = false;
      });
    }
  }

  bool get _isExamFlow => widget.quizId != null && widget.quizId!.isNotEmpty;
  bool get _isChallengeFlow => widget.challengeId != null && widget.challengeId!.isNotEmpty;
  bool get _isLevelExamFlow => widget.isLevelExam;

  int _correctAnswerIndexForQuestion(int questionIndex) {
    // Use correct_answer_index from dynamic questions if available
    if (_dynamicQuestions.isNotEmpty &&
        questionIndex < _dynamicQuestions.length) {
      final q = _dynamicQuestions[questionIndex];
      if (q.containsKey('correct_answer_index')) {
        return (q['correct_answer_index'] as int?) ?? 0;
      }
    }
    return 0;
  }

  int get _resolvedTotalQuestions {
    if (_dynamicQuestions.isNotEmpty) {
      return _dynamicQuestions.length;
    }
    return widget.totalQuestions <= 0 ? 1 : widget.totalQuestions;
  }

  String _questionText(int index) {
    if (_dynamicQuestions.isNotEmpty && index < _dynamicQuestions.length) {
      return _dynamicQuestions[index]['question'] as String;
    }
    return 'Just go ahead and select some answer from the ones below:';
  }

  List<String> _optionsForQuestion(int index) {
    if (_dynamicQuestions.isNotEmpty && index < _dynamicQuestions.length) {
      return List<String>.from(_dynamicQuestions[index]['options'] as List);
    }
    return const <String>['Answer 1', 'Answer 2', 'Answer 3', 'Answer 4'];
  }

  String? _imageUrlForQuestion(int index) {
    if (_dynamicQuestions.isNotEmpty && index < _dynamicQuestions.length) {
      return _dynamicQuestions[index]['image_url'] as String?;
    }
    return null;
  }

  Future<bool> _submitDiagnosticResult({
    required int resolvedTotalQuestions,
  }) async {
    try {
      final diagnosticDS = ref.read(diagnosticRemoteDataSourceProvider);

      // Use the new diagnostic_test_results table to upload raw answers only.
      // Wrap answers in an object to match the expected format {"answers": [...]}
      final bool inserted = await diagnosticDS.submitDiagnosticResult(
        testNumber: _testNumberFromTypeId(_diagnosticTestTypeId),
        rawAnswers: {
          'answers': _userRawAnswers,
        },
      );

      if (inserted) {
        final localDS = ref.read(assessmentLocalDataSourceProvider);
        localDS.clearCachedDiagnosticAnswers(_diagnosticTestTypeId);
      }

      _lastSubmitError = null;
      return inserted;
    } catch (e) {
      _lastSubmitError = e.toString();
      return false;
    }
  }

  int _testNumberFromTypeId(String typeId) {
    // Reusing logic from data source if needed, or simple mapping
    final list = [
      'ipip_exam',
      'soft_skills_exam',
      'vark_exam',
      'career_interest_exam',
      'iq_exam',
    ];
    final idx = list.indexOf(typeId);
    return idx >= 0 ? idx + 1 : 1;
  }

  Future<void> _finishFlow(BuildContext context) async {
    final int resolvedTotalQuestions = _resolvedTotalQuestions;

    final apiService = ref.read(learnovaApiServiceProvider);

    // ── Challenge Exam Flow ──
    if (_isChallengeFlow) {
      final future = apiService.submitChallengeAttempt(
        challengeId: widget.challengeId!,
        answers: { 'answers': _userRawAnswers },
      );

      if (context.mounted) {
        AppRouter.pushReplacement(
          context,
          TestCompleteScreen(
            testIndex: widget.testIndex,
            returnToMapOnContinue: true,
            standaloneTitle: widget.completionTitle ?? 'Weekly Challenge Complete',
            sourceNodeId: widget.sourceNodeId,
            evaluationFuture: future,
          ),
          routeName: AppRoutePaths.testComplete,
        );
      }
      return;
    }

    // ── Level Exam Flow ──
    if (_isLevelExamFlow) {
      final rawDiff = (widget.difficulty ?? 'mid').toLowerCase();
      final mappedDiff = rawDiff == 'medium' ? 'mid' : rawDiff;

      final future = apiService.submitLevelAttempt(
        examId: widget.quizId!,
        difficulty: mappedDiff,
        answers: { 'answers': _userRawAnswers },
      );

      if (context.mounted) {
        AppRouter.pushReplacement(
          context,
          TestCompleteScreen(
            testIndex: widget.testIndex,
            returnToMapOnContinue: true,
            standaloneTitle: widget.completionTitle ?? 'Level Complete',
            sourceNodeId: widget.sourceNodeId,
            evaluationFuture: future,
          ),
          routeName: AppRoutePaths.testComplete,
        );
      }
      return;
    }

    // ── Module Exam Flow ──
    if (_isExamFlow) {
      final rawDiff = (widget.difficulty ?? 'easy').toLowerCase();
      final mappedDiff = rawDiff == 'medium' ? 'mid' : rawDiff;

      final future = () async {
        final diagnosticDS = ref.read(diagnosticRemoteDataSourceProvider);
        final actualAssessmentId = await diagnosticDS.getAssessmentIdForModule(
          widget.quizId!,
          difficulty: mappedDiff,
        );
        if (actualAssessmentId == null) {
          throw Exception('Assessment not found for this module.');
        }

        return apiService.submitModuleAttempt(
          assessmentId: actualAssessmentId,
          answers: { 'answers': _userRawAnswers },
          difficulty: mappedDiff,
        );
      }();

      if (context.mounted) {
        AppRouter.pushReplacement(
          context,
          TestCompleteScreen(
            testIndex: widget.testIndex,
            returnToMapOnContinue: true,
            standaloneTitle: widget.completionTitle ?? 'Module Exam Complete',
            sourceNodeId: widget.sourceNodeId,
            evaluationFuture: future,
          ),
          routeName: AppRoutePaths.testComplete,
        );
      }
      return;
    }

    // Diagnostic Flow
    final inserted = await _submitDiagnosticResult(
      resolvedTotalQuestions: resolvedTotalQuestions,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            inserted
                ? 'Test result saved successfully.'
                : (_lastSubmitError ?? 'Failed to save test result.'),
          ),
          backgroundColor:
              inserted ? Colors.green.shade700 : Colors.red.shade700,
        ),
      );
    }

    if (!inserted) {
      return;
    }

    // Startup personality assessments are descriptive-only (no right/wrong score).
    if (!widget.returnToHomeOnFinish && widget.testIndex != 99) {
      if (!context.mounted) {
        return;
      }
      AppRouter.push(
        context,
        TestCompleteScreen(testIndex: widget.testIndex),
        routeName: AppRoutePaths.testComplete,
      );
      return;
    }

    // Quest Flow: Calculate score
    int? questScore;
    if (widget.testIndex == 99) {
      int correctCount = 0;
      for (int i = 0; i < _userRawAnswers.length; i++) {
        final answer = _userRawAnswers[i];
        final correctIdx = _correctAnswerIndexForQuestion(i);
        if (answer['selected_index'] == correctIdx) {
          correctCount++;
        }
      }
      questScore = ((correctCount / resolvedTotalQuestions) * 100).toInt();
    }

    // If it's the last test (IQ Exam, index 4), trigger the scoring engine.
    final bool isLastDiagnosticTest = !_isExamFlow && widget.testIndex == 4;
    
    debugPrint('DEBUG: Finishing quiz index: ${widget.testIndex} (Type: $_diagnosticTestTypeId)');
    
    if (isLastDiagnosticTest) {
      try {
        debugPrint('DEBUG: Waiting 3 seconds for DB safety...');
        await Future.delayed(const Duration(milliseconds: 3000)); 
        
        debugPrint('DEBUG: Calling run-scoring-engine Edge Function...');
        final api = ref.read(learnovaApiServiceProvider);
        final result = await api.runScoringEngine();
        debugPrint('DEBUG: AI Engine Triggered Successfully: $result');
        debugPrint('DEBUG: Edge Function Success Result: $result');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI Analysis started successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('DEBUG ERROR: Scoring engine trigger failed: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI Analysis trigger failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    if (!context.mounted) {
      return;
    }

    AppRouter.pushReplacement(
      context,
      TestCompleteScreen(
        testIndex: widget.testIndex,
        returnToMapOnContinue: true,
        standaloneTitle: widget.completionTitle,
        sourceNodeId: widget.sourceNodeId,
        scorePercentage: questScore,
        didPass: questScore == null || questScore >= widget.passThreshold,
      ),
      routeName: AppRoutePaths.testComplete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final int resolvedTotalQuestions = _resolvedTotalQuestions;
    double progress = (_currentQuestionIndex + 1) / resolvedTotalQuestions;

    if (_isLoadingQuestions) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_dynamicQuestions.isEmpty && (_isExamFlow || !widget.returnToHomeOnFinish)) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No questions found for this quiz.\n(ID: ${widget.quizId}\nDifficulty: ${widget.difficulty})',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textTitle,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Back',
                    backgroundColor: colors.buttonBackground,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final List<String> options = _optionsForQuestion(_currentQuestionIndex);

    // ── Read perk state for current question (exam flow only) ──
    final String currentQuestionId = _dynamicQuestions.isNotEmpty &&
            _currentQuestionIndex < _dynamicQuestions.length
        ? (_dynamicQuestions[_currentQuestionIndex]['id']?.toString() ?? '')
        : '';

    // Perk effects for the current question.
    String? perkHint;
    String? eliminatedOptionKey;
    String? eliminatedOptionValue;
    if (_isExamFlow) {
      final perkState = ref.watch(perkDeckViewModelProvider);
      perkHint = perkState.hintForQuestion(currentQuestionId);
      eliminatedOptionKey =
          perkState.eliminatedOptionKeyForQuestion(currentQuestionId);
      eliminatedOptionValue =
          perkState.eliminatedOptionForQuestion(currentQuestionId);
    }

    return SpaceScaffold(
      topWavePaths: [AppAssets.testStartTop],
      bottomWavePaths: [AppAssets.testStartBottom],
      child: SafeArea(
        child: Stack(
          children: [
            // ── Main content ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          AppAssets.starIcon,
                          width: 60,
                          height: 60,
                        ),
                        Text(
                          '${((_currentQuestionIndex + 1) / resolvedTotalQuestions * 100).toInt()}%',
                          style: const TextStyle(
                            color: ColorManager.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colors.isDark ? ColorManager.overlaySoft : Colors.grey.shade300,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(ColorManager.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ── Scrollable question + options area ──
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Q.${_currentQuestionIndex + 1}',
                            style: TextStyle(
                              color: colors.textTitle,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _questionText(_currentQuestionIndex),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                          // ── Optional question image ──
                          if (_imageUrlForQuestion(_currentQuestionIndex) != null) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _imageUrlForQuestion(_currentQuestionIndex)!,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('[QuizScreen] Image failed to load: $error');
                                    debugPrint('[QuizScreen] Failed URL: ${_imageUrlForQuestion(_currentQuestionIndex)}');
                                    return Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: colors.cardBackground,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_outlined,
                                            size: 48,
                                            color: colors.textSecondary,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Image failed to load',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                          // ── Owl of Wisdom hint (shown when perk is used) ──
                          if (perkHint != null) ...[
                            const SizedBox(height: 16),
                            _buildHintCard(perkHint, colors),
                          ],
                          const SizedBox(height: 30),
                          
                          if (_isLevelExamFlow) ...[
                            // Essay Text Field for Level Exams
                            TextField(
                              controller: _essayController,
                              maxLines: 8,
                              onChanged: (text) {
                                setState(() {});
                              },
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type your essay answer here...',
                                hintStyle: TextStyle(
                                  color: colors.textSecondary.withValues(alpha: 0.6),
                                ),
                                filled: true,
                                fillColor: colors.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.borderWeak, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.borderWeak, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                            ),
                          ] else ...[
                            // MCQ Options for other exams
                            ...List.generate(options.length, (index) {
                              final optionText = options[index];
                              bool isSelected = _selectedAnswerIndex == index;
                              final question = _dynamicQuestions.isNotEmpty 
                                  ? _dynamicQuestions[_currentQuestionIndex] 
                                  : null;
                              final choiceValues = question?['choiceValues'] as List<dynamic>?;
                              final optionValue = choiceValues?[index]?.toString() ?? optionText;
                              
                              final bool isEliminated =
                                  (eliminatedOptionValue != null && eliminatedOptionValue == optionText) ||
                                  (eliminatedOptionKey != null && eliminatedOptionKey == optionValue);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: GestureDetector(
                                onTap: isEliminated
                                    ? null // Eliminated options are not tappable
                                    : () {
                                        setState(() {
                                          _selectedAnswerIndex = index;
                                        });
                                      },
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 400),
                                  opacity: isEliminated ? 0.3 : 1.0,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: isSelected && !isEliminated
                                          ? colors.primary
                                          : colors.cardBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected && !isEliminated
                                          ? Border.all(
                                              color: colors.primary, width: 2)
                                          : Border.all(
                                              color: colors.borderWeak, width: 1),
                                    ),
                                    child: Text(
                                      optionText,
                                      style: TextStyle(
                                        color: isSelected && !isEliminated
                                            ? (colors.isDark
                                                ? ColorManager.secondary
                                                : colors.buttonForeground)
                                            : colors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        decoration: isEliminated
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor:
                                            colors.textPrimary.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          ],
                          // Extra bottom spacing so content isn't hidden by perk deck
                          SizedBox(height: _isExamFlow ? 80 : 16),
                        ],
                      ),
                    ),
                  ),
                  // ── Pinned button at bottom ──
                  const SizedBox(height: 16),
                  CustomButton(
                    text: _currentQuestionIndex < resolvedTotalQuestions - 1
                        ? 'Next Question'
                        : 'Finish Quiz',
                    backgroundColor: colors.buttonBackground,
                    onPressed: (_isLevelExamFlow ? _essayController.text.trim().isNotEmpty : _selectedAnswerIndex != null)
                        ? () async {
                            final question = _dynamicQuestions.isNotEmpty 
                                ? _dynamicQuestions[_currentQuestionIndex] 
                                : {'id': 'q$_currentQuestionIndex', 'question_key': 'key$_currentQuestionIndex'};
                            
                            if (_isLevelExamFlow) {
                              _userRawAnswers.add({
                                'question_id': question['id'],
                                'question_key': question['question_key'],
                                'essay_answer': _essayController.text.trim(),
                              });
                              _essayController.clear();
                            } else {
                              final options = _optionsForQuestion(_currentQuestionIndex);
                              final choiceValues = question['choiceValues'] as List<dynamic>?;
                              final value = choiceValues?[_selectedAnswerIndex!]?.toString() ?? options[_selectedAnswerIndex!];
                              
                                _userRawAnswers.add({
                                  'question_id': question['id'],
                                  'question_key': question['question_key'],
                                  'selected_index': _selectedAnswerIndex,
                                  'selected_label': options[_selectedAnswerIndex!],
                                  'selected_value': value,
                                  'answer': value,
                                });
                              }

                              if (!_isExamFlow && !_isLevelExamFlow && !_isChallengeFlow) {
                                final localDS = ref.read(assessmentLocalDataSourceProvider);
                                localDS.cacheDiagnosticAnswers(_diagnosticTestTypeId, _userRawAnswers);
                              }

                            if (_currentQuestionIndex <
                                resolvedTotalQuestions - 1) {
                              setState(() {
                                _currentQuestionIndex++;
                                _selectedAnswerIndex = null;
                              });
                            } else {
                              await _finishFlow(context);
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // ── Perk Deck Overlay (Module Exams only) ──
            if (_isExamFlow && currentQuestionId.isNotEmpty)
              PerkDeckOverlay(
                currentQuestionId: currentQuestionId,
                isCurrentQuestionMcq: true, // All module questions are MCQ
                onPerkCast: () {
                  // Determine which perk was just cast for the effect animation.
                  final perkState = ref.read(perkDeckViewModelProvider);
                  if (perkState.justCastPerkId != null) {
                    final castPerk = perkState.perks.firstWhere(
                      (p) => p.id == perkState.justCastPerkId,
                      orElse: () => OwlOfWisdomPerk(),
                    );
                    setState(() => _activeCastEffect = castPerk);
                    ref.read(perkDeckViewModelProvider.notifier).clearJustCast();
                  }
                },
              ),

            // ── Perk cast effect animation ──
            if (_activeCastEffect != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: PerkCastEffect(
                      perk: _activeCastEffect!,
                      onComplete: () {
                        if (mounted) {
                          setState(() => _activeCastEffect = null);
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the animated hint card shown when Owl of Wisdom is used.
  Widget _buildHintCard(String hint, AppColors colors) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD54F).withValues(alpha: 0.12),
              const Color(0xFFFFA726).withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFFD54F),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Owl\'s Hint',
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

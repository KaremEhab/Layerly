import 'dart:async';
import 'package:flutter/material.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/core/widgets/app_dialog.dart';
import 'package:layerly/core/widgets/app_modal_sheet.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_event.dart';
import 'package:layerly/features/editor/presentation/screens/editor_screen.dart';
import '../../data/gemini_ai_client.dart';
import '../../domain/services/ai_agent_service.dart';

class AiAgentSheet extends StatefulWidget {
  final EditorBloc? editorBloc;

  const AiAgentSheet({
    super.key,
    this.editorBloc,
  });

  static Future<void> show(BuildContext context, {EditorBloc? editorBloc}) {
    return showAppModalSheet(
      context: context,
      builder: (_) => AiAgentSheet(editorBloc: editorBloc),
    );
  }

  @override
  State<AiAgentSheet> createState() => _AiAgentSheetState();
}

class _AiAgentSheetState extends State<AiAgentSheet> {
  final TextEditingController _promptController = TextEditingController(
    text: 'create me a new graphic design with 1:1 ratio and with gradient bg and featuring pharma stuff',
  );

  bool _isGenerating = false;
  String _currentStepMessage = '';
  double _currentProgress = 0.0;
  AiGenerationResult? _generatedResult;
  String? _errorMessage;

  // Options
  String _selectedAspectRatio = '1:1';
  String _selectedLayoutStyle = 'auto';
  String _selectedAesthetic = 'glass';
  bool _applyAsNewSlide = true;
  String? _savedApiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await AiAgentService.instance.getStoredApiKey();
    if (mounted) {
      setState(() => _savedApiKey = key);
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final buffer = StringBuffer(prompt);
    buffer.write(' [ratio: $_selectedAspectRatio]');
    if (_selectedLayoutStyle != 'auto') {
      buffer.write(' [layoutStyle: $_selectedLayoutStyle]');
    }
    if (_selectedAesthetic != 'glass') {
      buffer.write(' [cardAesthetic: $_selectedAesthetic]');
    }
    final fullPrompt = buffer.toString();

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedResult = null;
      _currentProgress = 0.15;
      _currentStepMessage = 'Initializing Layerly AI Agent...';
    });

    try {
      final activePage = widget.editorBloc?.state.activePage;
      final padH = activePage?.horizontalPadding ?? 20.0;
      final padV = activePage?.verticalPadding ?? 20.0;

      final result = await AiAgentService.instance.generateDesign(
        prompt: fullPrompt,
        horizontalPadding: padH,
        verticalPadding: padV,
        onProgress: (step) {
          if (mounted) {
            setState(() {
              _currentStepMessage = step.message;
              _currentProgress = step.progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatedResult = result;
          _currentProgress = 1.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Generation failed: $e';
        });
      }
    }
  }

  void _openInStudio(AiGenerationResult result) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(project: result.project),
      ),
    );
  }

  void _applyToEditor(AiGenerationResult result) {
    if (widget.editorBloc == null) return;
    widget.editorBloc!.add(
      ApplyAiDesignEvent(
        result.page,
        asNewPage: _applyAsNewSlide,
      ),
    );
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F1B38),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFA78BFA), size: 18),
            const SizedBox(width: 10),
            Text(
              _applyAsNewSlide ? 'New AI Slide added to project!' : 'AI Design applied to canvas (Undo available)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _savedApiKey ?? '');
    bool isTesting = false;
    String? testFeedback;
    bool isTestSuccess = false;

    showAppDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AppDialog(
          icon: Icons.key_rounded,
          title: 'Google Gemini API Key',
          subtitle: 'Configure your API key for dynamic open-ended reasoning & design generation.',
          customActions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            if (_savedApiKey != null && _savedApiKey!.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await AiAgentService.instance.removeApiKey();
                  await _loadApiKey();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Remove Key', style: TextStyle(color: Colors.redAccent)),
              ),
            const SizedBox(width: 4),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final newKey = controller.text.trim();
                if (newKey.isEmpty) {
                  await AiAgentService.instance.removeApiKey();
                } else {
                  await AiAgentService.instance.saveApiKey(newKey);
                }
                await _loadApiKey();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Key', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: isTesting
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D2B4)),
                          ),
                        )
                      : TextButton(
                          onPressed: () async {
                            final candidate = controller.text.trim();
                            if (candidate.isEmpty) {
                              setDialogState(() {
                                testFeedback = 'Please enter an API key to test.';
                                isTestSuccess = false;
                              });
                              return;
                            }
                            setDialogState(() {
                              isTesting = true;
                              testFeedback = null;
                            });
                            try {
                              final message = await GeminiAiClient.testApiKey(candidate);
                              setDialogState(() {
                                isTesting = false;
                                testFeedback = message;
                                isTestSuccess = true;
                              });
                            } catch (e) {
                              setDialogState(() {
                                isTesting = false;
                                testFeedback = e.toString().replaceAll('Exception: ', '');
                                isTestSuccess = false;
                              });
                            }
                          },
                          child: const Text(
                            'Test Key',
                            style: TextStyle(color: Color(0xFF00D2B4), fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                ),
              ),
              if (testFeedback != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isTestSuccess
                        ? const Color(0xFF00D2B4).withValues(alpha: 0.12)
                        : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTestSuccess
                          ? const Color(0xFF00D2B4).withValues(alpha: 0.35)
                          : Colors.red.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isTestSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        color: isTestSuccess ? const Color(0xFF00D2B4) : Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          testFeedback!,
                          style: TextStyle(
                            color: isTestSuccess ? const Color(0xFF00D2B4) : Colors.redAccent,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'Get your free Gemini API key from Google AI Studio (aistudio.google.com). Automatic fallback across Gemini 2.0 Flash and 1.5 Flash.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInsideEditor = widget.editorBloc != null;

    return AppModalSheet(
      icon: Icons.auto_awesome_rounded,
      title: 'Layerly AI Design Agent',
      subtitle: 'Natural language generative design engine with AutoLayout & rich palettes',
      trailing: IconButton(
        icon: Icon(
          Icons.settings_suggest_rounded,
          color: _savedApiKey != null && _savedApiKey!.isNotEmpty
              ? const Color(0xFF00D2B4)
              : AppColors.textMuted,
          size: 20,
        ),
        tooltip: 'Gemini API Key Settings',
        onPressed: _showApiKeyDialog,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prompt Input Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isGenerating
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                    : AppColors.border,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _promptController,
                  enabled: !_isGenerating,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  decoration: const InputDecoration(
                    hintText: 'Describe the design you want (e.g. 1:1 pharma graphic with gradient bg)...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Engine indicator pill
                    InkWell(
                      onTap: _showApiKeyDialog,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _savedApiKey != null && _savedApiKey!.isNotEmpty
                              ? const Color(0xFF00D2B4).withValues(alpha: 0.15)
                              : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _savedApiKey != null && _savedApiKey!.isNotEmpty
                                  ? Icons.psychology_rounded
                                  : Icons.offline_bolt_rounded,
                              size: 13,
                              color: _savedApiKey != null && _savedApiKey!.isNotEmpty
                                  ? const Color(0xFF00D2B4)
                                  : const Color(0xFFA78BFA),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _savedApiKey != null && _savedApiKey!.isNotEmpty
                                  ? 'Gemini Live AI (Key Active)'
                                  : 'Studio Synthesis Engine (No Key)',
                              style: TextStyle(
                                color: _savedApiKey != null && _savedApiKey!.isNotEmpty
                                    ? const Color(0xFF00D2B4)
                                    : const Color(0xFFA78BFA),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_promptController.text.isNotEmpty && !_isGenerating)
                      InkWell(
                        onTap: () {
                          _promptController.clear();
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Clear',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Aspect Ratio Selector
          Row(
            children: [
              const Text(
                'Ratio:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              _buildRatioChip('1:1 (Square)'),
              const SizedBox(width: 6),
              _buildRatioChip('4:5 (Portrait)'),
              const SizedBox(width: 6),
              _buildRatioChip('9:16 (Story)'),
              const SizedBox(width: 6),
              _buildRatioChip('16:9 (Banner)'),
            ],
          ),
          const SizedBox(height: 10),

          // Layout Archetype Selector (Figma Architecture)
          Row(
            children: [
              const Text(
                'Layout:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildLayoutChip('auto', '✨ Auto (AI)'),
                      const SizedBox(width: 6),
                      _buildLayoutChip('splitBento', '🍱 Bento Grid'),
                      const SizedBox(width: 6),
                      _buildLayoutChip('featureGrid', '🔳 2x2 Grid'),
                      const SizedBox(width: 6),
                      _buildLayoutChip('statisticFocus', '📊 Stat Focus'),
                      const SizedBox(width: 6),
                      _buildLayoutChip('heroCards', '⚡ Hero Cards'),
                      const SizedBox(width: 6),
                      _buildLayoutChip('centeredMinimal', '✨ Minimal'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Aesthetic Mood Selector
          Row(
            children: [
              const Text(
                'Mood:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAestheticChip('glass', '🔮 Dark Glass'),
                      const SizedBox(width: 6),
                      _buildAestheticChip('gradientBorder', '💜 Cyberpunk'),
                      const SizedBox(width: 6),
                      _buildAestheticChip('solidElevated', '🧬 Clinical Biotech'),
                      const SizedBox(width: 6),
                      _buildAestheticChip('minimal', '📰 Editorial Minimal'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Prompt Ideas
          const Text(
            'Quick Inspiration:',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip(
                  '🍱 Bento SaaS Dashboard',
                  'next-gen AI developer tools bento grid layout with 1 hero tile and 2 companion metric cards',
                ),
                const SizedBox(width: 8),
                _buildPromptChip(
                  '📊 3-KPI Growth Stats',
                  'quarterly financial revenue and latency statistics focus post with big numbers and trend tags',
                ),
                const SizedBox(width: 8),
                _buildPromptChip(
                  '💊 Pharma 1:1 Clinical',
                  'precision pharmacology clinical drug delivery system 1:1 post with cyan gradient',
                ),
                const SizedBox(width: 8),
                _buildPromptChip(
                  '🔳 2x2 Cloud Grid',
                  'cloud infrastructure 4 core capabilities in a balanced 2x2 grid with high-speed metrics',
                ),
                const SizedBox(width: 8),
                _buildPromptChip(
                  '✨ Editorial Minimal',
                  'minimalist luxury design studio announcement with elegant typography and dividers',
                ),
              ],
            ),
          ),

          // Target selector if inside editor
          if (isInsideEditor) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.view_carousel_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Insert as:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Spacer(),
                  ChoiceChip(
                    label: const Text('New Slide', style: TextStyle(fontSize: 11)),
                    selected: _applyAsNewSlide,
                    onSelected: (val) => setState(() => _applyAsNewSlide = true),
                    selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    backgroundColor: Colors.transparent,
                    labelStyle: TextStyle(
                      color: _applyAsNewSlide ? const Color(0xFFA78BFA) : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text('Active Slide', style: TextStyle(fontSize: 11)),
                    selected: !_applyAsNewSlide,
                    onSelected: (val) => setState(() => _applyAsNewSlide = false),
                    selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    backgroundColor: Colors.transparent,
                    labelStyle: TextStyle(
                      color: !_applyAsNewSlide ? const Color(0xFFA78BFA) : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Progress State / Result
          if (_isGenerating) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1435).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF00D2B4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentStepMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _currentProgress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_generatedResult != null) ...[
            // Generated Result Card Preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF041C24).withValues(alpha: 0.8),
                    const Color(0xFF131722).withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _generatedResult!.isGeminiGenerated
                      ? const Color(0xFF00D2B4).withValues(alpha: 0.5)
                      : const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _generatedResult!.isGeminiGenerated ? Icons.auto_awesome_rounded : Icons.check_circle_rounded,
                        color: _generatedResult!.isGeminiGenerated ? const Color(0xFF00D2B4) : const Color(0xFFA78BFA),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _generatedResult!.isGeminiGenerated
                              ? 'Generated via ${_generatedResult!.modelUsed ?? "Gemini"}'
                              : 'Synthesized via Studio Engine',
                          style: TextStyle(
                            color: _generatedResult!.isGeminiGenerated ? const Color(0xFF00D2B4) : const Color(0xFFA78BFA),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D2B4).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _generatedResult!.recipe.layoutStyle.name.toUpperCase(),
                          style: const TextStyle(color: Color(0xFF00D2B4), fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_generatedResult!.page.layers.length} Layers',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  if (_generatedResult!.geminiError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Gemini API note: ${_generatedResult!.geminiError}',
                              style: const TextStyle(color: Colors.amber, fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: _showApiKeyDialog,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                'Check Key',
                                style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _generatedResult!.recipe.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Outfit',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _generatedResult!.recipe.subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (isInsideEditor)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _applyToEditor(_generatedResult!),
                            icon: const Icon(Icons.done_all_rounded, size: 16),
                            label: Text(_applyAsNewSlide ? 'Insert as Slide' : 'Apply to Canvas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D2B4),
                              foregroundColor: const Color(0xFF041C24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openInStudio(_generatedResult!),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Open in Layerly Studio'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Primary Generate Action
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _startGeneration,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              _isGenerating ? 'Synthesizing Design...' : 'Generate Design with AI',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioChip(String label) {
    final ratioKey = label.split(' ').first;
    final isSelected = _selectedAspectRatio == ratioKey;
    return InkWell(
      onTap: () => setState(() => _selectedAspectRatio = ratioKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.25) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFA78BFA) : AppColors.border,
          ),
        ),
        child: Text(
          ratioKey,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutChip(String styleKey, String label) {
    final isSelected = _selectedLayoutStyle == styleKey;
    return InkWell(
      onTap: () => setState(() => _selectedLayoutStyle = styleKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D2B4).withValues(alpha: 0.20) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D2B4) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAestheticChip(String aestheticKey, String label) {
    final isSelected = _selectedAesthetic == aestheticKey;
    return InkWell(
      onTap: () => setState(() => _selectedAesthetic = aestheticKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.25) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFA78BFA) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPromptChip(String title, String fullPrompt) {
    return InkWell(
      onTap: () {
        setState(() {
          _promptController.text = fullPrompt;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

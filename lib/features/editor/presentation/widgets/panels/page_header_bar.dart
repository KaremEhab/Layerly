import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/app_colors.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_state.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/figma_context_menu.dart';
import 'package:layerly/core/widgets/more_rings_icon.dart';

class PageHeaderBar extends StatelessWidget {
  final VoidCallback? onToggleFullscreen;

  const PageHeaderBar({
    super.key,
    this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      builder: (context, state) {
        final activePage = state.activePage;

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.background,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current Page Title
              Text(
                activePage.name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),

              // Fullscreen & More Actions
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.crop_free_rounded, size: 20),
                    color: AppColors.text,
                    tooltip: 'Fullscreen Editor',
                    onPressed: onToggleFullscreen,
                  ),
                  const SizedBox(width: 4),
                  Builder(
                    builder: (btnContext) => IconButton(
                      icon: const MoreRingsIcon(color: AppColors.text, size: 22, ringRadius: 2.5, strokeWidth: 1.6, spacing: 1.0),
                      color: AppColors.text,
                      tooltip: 'Page Options',
                      onPressed: () {
                        final box = btnContext.findRenderObject() as RenderBox?;
                        final pos = box != null
                            ? box.localToGlobal(Offset(0, box.size.height + 6))
                            : const Offset(300, 200);
                        showFigmaContextMenu(
                          context: context,
                          globalPosition: pos,
                          state: state,
                          bloc: context.read<EditorBloc>(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

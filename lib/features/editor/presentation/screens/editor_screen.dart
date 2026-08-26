import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layerly/core/constants/sample_project.dart';
import 'package:layerly/features/editor/domain/entities/canvas_project.dart';
import 'package:layerly/features/editor/presentation/bloc/editor_bloc.dart';
import 'package:layerly/features/editor/presentation/widgets/responsive/responsive_editor_layout.dart';

class EditorScreen extends StatelessWidget {
  final CanvasProject? project;

  const EditorScreen({
    super.key,
    this.project,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditorBloc(
        initialProject: project ?? SampleProject.createUberRedesignProject(),
      ),
      child: const ResponsiveEditorLayout(),
    );
  }
}


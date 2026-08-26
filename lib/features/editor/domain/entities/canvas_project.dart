import 'package:equatable/equatable.dart';
import 'canvas_page.dart';
import 'component_definition.dart';

class CanvasProject extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<CanvasPage> pages;
  final int activePageIndex;
  final int coverPageIndex;
  final List<ComponentDefinition> components;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CanvasProject({
    required this.id,
    required this.name,
    this.description = '',
    required this.pages,
    this.activePageIndex = 0,
    this.coverPageIndex = 0,
    this.components = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  CanvasPage get activePage {
    if (pages.isEmpty) {
      return const CanvasPage(id: 'default', name: 'Page 1');
    }
    if (activePageIndex < 0 || activePageIndex >= pages.length) {
      return pages.first;
    }
    return pages[activePageIndex];
  }

  CanvasPage get coverPage {
    if (pages.isEmpty) {
      return const CanvasPage(id: 'default', name: 'Cover');
    }
    if (coverPageIndex >= 0 && coverPageIndex < pages.length) {
      return pages[coverPageIndex];
    }
    return pages.first;
  }

  CanvasProject copyWith({
    String? id,
    String? name,
    String? description,
    List<CanvasPage>? pages,
    int? activePageIndex,
    int? coverPageIndex,
    List<ComponentDefinition>? components,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CanvasProject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pages: pages ?? this.pages,
      activePageIndex: activePageIndex ?? this.activePageIndex,
      coverPageIndex: coverPageIndex ?? this.coverPageIndex,
      components: components ?? this.components,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        pages,
        activePageIndex,
        coverPageIndex,
        components,
        createdAt,
        updatedAt,
      ];
}

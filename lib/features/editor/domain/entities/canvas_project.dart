import 'package:equatable/equatable.dart';
import 'canvas_page.dart';
import 'component_definition.dart';

class CanvasProject extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<CanvasPage> pages;
  final int activePageIndex;
  final List<ComponentDefinition> components;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CanvasProject({
    required this.id,
    required this.name,
    this.description = '',
    required this.pages,
    this.activePageIndex = 0,
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

  CanvasProject copyWith({
    String? id,
    String? name,
    String? description,
    List<CanvasPage>? pages,
    int? activePageIndex,
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
        components,
        createdAt,
        updatedAt,
      ];
}

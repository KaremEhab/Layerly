import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/sample_project.dart';
import '../../../core/utils/uuid_generator.dart';
import '../domain/entities/canvas_page.dart';
import '../domain/entities/canvas_project.dart';
import '../domain/entities/layer_enums.dart';
import '../domain/entities/text_layer.dart';
import 'project_serializer.dart';

class ProjectStorageService {
  static const String _keysListKey = 'layerly_project_ids_v1';
  static const String _projectKeyPrefix = 'layerly_project_v1_';

  /// Singleton instance
  static final ProjectStorageService instance = ProjectStorageService._();
  ProjectStorageService._();

  /// Retrieve all projects from persistent storage.
  /// If storage is empty, automatically seeds with initial showcase sample projects.
  Future<List<CanvasProject>> getAllProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final idList = prefs.getStringList(_keysListKey);

    if (idList == null || idList.isEmpty) {
      // First run: Seed showcase sample project and a creative starter
      final seededProjects = _createSeedProjects();
      for (final p in seededProjects) {
        await saveProject(p);
      }
      return seededProjects;
    }

    final projects = <CanvasProject>[];
    for (final id in idList) {
      final jsonStr = prefs.getString('$_projectKeyPrefix$id');
      if (jsonStr != null) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final project = ProjectSerializer.projectFromJson(map);
          projects.add(project);
        } catch (e) {
          debugPrint('Error decoding project $id: $e');
        }
      }
    }

    // Sort by most recently updated
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  /// Load a single project by ID.
  Future<CanvasProject?> getProjectById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_projectKeyPrefix$id');
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ProjectSerializer.projectFromJson(map);
    } catch (e) {
      debugPrint('Error loading project $id: $e');
      return null;
    }
  }

  /// Save or update a project in persistent storage.
  Future<void> saveProject(CanvasProject project) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = ProjectSerializer.projectToJson(project);
    final jsonStr = jsonEncode(jsonMap);

    await prefs.setString('$_projectKeyPrefix${project.id}', jsonStr);

    final idList = prefs.getStringList(_keysListKey) ?? [];
    if (!idList.contains(project.id)) {
      idList.insert(0, project.id);
      await prefs.setStringList(_keysListKey, idList);
    }
  }

  /// Delete a project by ID.
  Future<void> deleteProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_projectKeyPrefix$id');

    final idList = prefs.getStringList(_keysListKey) ?? [];
    idList.remove(id);
    await prefs.setStringList(_keysListKey, idList);
  }

  /// Duplicate a project with a new ID and title.
  Future<CanvasProject> duplicateProject(CanvasProject original) async {
    final newId = UuidGenerator.generate();
    final duplicated = original.copyWith(
      id: newId,
      name: '${original.name} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveProject(duplicated);
    return duplicated;
  }

  /// Create a new project from a name, canvas dimensions, and template.
  Future<CanvasProject> createNewProject({
    required String name,
    required double width,
    required double height,
    String? description,
    List<CanvasPage>? initialPages,
  }) async {
    final newId = UuidGenerator.generate();
    final pages = initialPages ??
        [
          CanvasPage(
            id: UuidGenerator.generate(),
            name: 'Slide 01',
            width: width,
            height: height,
            backgroundType: BackgroundType.gradient,
            backgroundColor: const Color(0xFF0D0B14),
            layers: [
              TextLayer(
                id: UuidGenerator.generate(),
                name: 'Heading',
                x: width * 0.1,
                y: height * 0.15,
                width: width * 0.8,
                height: 80,
                content: name,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                color: Colors.white,
              ),
            ],
          ),
        ];

    final project = CanvasProject(
      id: newId,
      name: name,
      description: description ?? 'Created with Layerly Studio',
      pages: pages,
      activePageIndex: 0,
      coverPageIndex: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveProject(project);
    return project;
  }

  /// Default projects seed
  List<CanvasProject> _createSeedProjects() {
    final uber = SampleProject.createUberRedesignProject();

    // Starter 2: Instagram Carousel Concept
    final page1 = CanvasPage(
      id: UuidGenerator.generate(),
      name: 'Cover Slide',
      width: 1080,
      height: 1080,
      backgroundType: BackgroundType.gradient,
      backgroundColor: const Color(0xFF0F0E17),
      layers: [
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Badge',
          x: 80,
          y: 100,
          width: 300,
          height: 38,
          content: '⚡ DESIGN TIPS & TRICKS',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF8B5CF6),
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Hero Title',
          x: 80,
          y: 160,
          width: 800,
          height: 140,
          content: '5 Visual Hierarchy\nRules for UI Design',
          fontSize: 48,
          fontWeight: FontWeight.w800,
          fontFamily: 'Outfit',
          color: Colors.white,
        ),
        TextLayer(
          id: UuidGenerator.generate(),
          name: 'Subtitle',
          x: 80,
          y: 330,
          width: 700,
          height: 60,
          content: 'Swipe to master scale, contrast, and layout balance.',
          fontSize: 22,
          color: Colors.white70,
        ),
      ],
    );

    final instaProject = CanvasProject(
      id: 'proj-insta-carousel-template',
      name: 'UI Hierarchy Carousel',
      description: 'Instagram Carousel 1080x1080',
      pages: [page1],
      activePageIndex: 0,
      coverPageIndex: 0,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    );

    return [uber, instaProject];
  }
}

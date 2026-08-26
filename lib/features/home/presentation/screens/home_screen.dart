import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/responsive_breakpoints.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/glass_popup_menu.dart';
import '../../../editor/data/project_storage_service.dart';
import '../../../editor/domain/entities/canvas_project.dart';
import '../../../editor/presentation/screens/editor_screen.dart';
import '../widgets/cover_slide_picker_sheet.dart';
import '../widgets/new_project_sheet.dart';
import '../widgets/project_cover_thumbnail.dart';

enum ProjectSortBy {
  recentlyEdited('Recently Edited'),
  newest('Newest First'),
  name('Name (A-Z)'),
  slides('Most Slides');

  final String label;
  const ProjectSortBy(this.label);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CanvasProject> _projects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ProjectSortBy _sortBy = ProjectSortBy.recentlyEdited;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final list = await ProjectStorageService.instance.getAllProjects();
    if (!mounted) return;
    setState(() {
      _projects = list;
      _isLoading = false;
    });
  }

  List<CanvasProject> get _filteredProjects {
    var list = List<CanvasProject>.from(_projects);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.pages.any((page) => page.name.toLowerCase().contains(q));
      }).toList();
    }

    switch (_sortBy) {
      case ProjectSortBy.recentlyEdited:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case ProjectSortBy.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProjectSortBy.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ProjectSortBy.slides:
        list.sort((a, b) => b.pages.length.compareTo(a.pages.length));
        break;
    }

    return list;
  }

  Future<void> _openProject(CanvasProject project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(project: project),
      ),
    );
    // Reload projects when returning from Editor
    _loadProjects();
  }

  Future<void> _showNewProjectModal() async {
    final created = await NewProjectSheet.show(context);
    if (created != null && mounted) {
      _openProject(created);
    }
  }

  Future<void> _duplicateProject(CanvasProject project) async {
    final copy = await ProjectStorageService.instance.duplicateProject(project);
    await _loadProjects();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            Text('Duplicated as "${copy.name}"', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProject(CanvasProject project) async {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.delete_outline_rounded,
        title: 'Delete Project?',
        subtitle: 'Are you sure you want to delete "${project.name}"?',
        confirmLabel: 'Delete',
        isDestructiveConfirm: true,
        content: const Text(
          'This will permanently remove the project and all its slides from local storage. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        onConfirm: () async {
          Navigator.pop(ctx);
          await ProjectStorageService.instance.deleteProject(project.id);
          _loadProjects();
        },
      ),
    );
  }

  void _renameProject(CanvasProject project) {
    final controller = TextEditingController(text: project.name);
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.edit_note_rounded,
        title: 'Rename Project',
        subtitle: 'Enter a new title for this design',
        confirmLabel: 'Save',
        onConfirm: () async {
          final newName = controller.text.trim();
          if (newName.isNotEmpty) {
            final updated = project.copyWith(name: newName, updatedAt: DateTime.now());
            await ProjectStorageService.instance.saveProject(updated);
            _loadProjects();
          }
          if (ctx.mounted) Navigator.pop(ctx);
        },
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceSecondary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  Future<void> _pickProjectCover(CanvasProject project) async {
    final selectedIndex = await CoverSlidePickerSheet.show(context, project);
    if (selectedIndex != null) {
      _loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFF09080E),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProjects,
          color: const Color(0xFF8B5CF6),
          backgroundColor: AppColors.surfaceElevated,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Top Hero & Branding App Bar
              SliverToBoxAdapter(
                child: _buildHeroHeader(context, isMobile),
              ),

              // 2. Quick Starter Templates Carousel
              SliverToBoxAdapter(
                child: _buildTemplatesSection(context),
              ),

              // 3. Search, Filter & View Mode Controls
              SliverToBoxAdapter(
                child: _buildFilterBar(context),
              ),

              // 4. Projects Grid / List View
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  ),
                )
              else if (_filteredProjects.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else if (_isGridView)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 4,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: isMobile ? 0.76 : 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final project = _filteredProjects[index];
                        return _buildProjectGridCard(project);
                      },
                      childCount: _filteredProjects.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final project = _filteredProjects[index];
                        return _buildProjectListTile(project);
                      },
                      childCount: _filteredProjects.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 60),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewProjectModal,
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'New Design',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  // ==========================================
  // Header Section
  // ==========================================
  Widget _buildHeroHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                // Logo Icon Box
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.layers_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFD8B4FE)],
                        ).createShader(bounds),
                        child: const Text(
                          'Layerly Studio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            fontFamily: 'Outfit',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(
                        'Visual Content & Mockup Studio',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Quick New Action
          InkWell(
            onTap: _showNewProjectModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: Color(0xFFA78BFA)),
                  SizedBox(width: 6),
                  Text(
                    'Create',
                    style: TextStyle(
                      color: Color(0xFFA78BFA),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Quick Starter Templates Shelf
  // ==========================================
  Widget _buildTemplatesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              'START FROM TEMPLATE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: kCanvasPresets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final preset = kCanvasPresets[index];
                return InkWell(
                  onTap: () async {
                    final created = await ProjectStorageService.instance.createNewProject(
                      name: '${preset.title} Design',
                      width: preset.width,
                      height: preset.height,
                    );
                    _openProject(created);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(preset.icon, size: 14, color: const Color(0xFFA78BFA)),
                            ),
                            const Spacer(),
                            Text(
                              preset.ratio,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preset.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Filter & Search Bar
  // ==========================================
  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Search Field
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search designs...',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        InkWell(
                          onTap: () => setState(() => _searchQuery = ''),
                          child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Sort Menu
              GlassPopupMenuButton<ProjectSortBy>(
                width: 210,
                onSelected: (sort) => setState(() => _sortBy = sort),
                itemBuilder: (context) => [
                  const GlassMenuHeader<ProjectSortBy>(
                    title: 'Sort Designs',
                    icon: Icons.sort_rounded,
                  ),
                  const GlassMenuDivider<ProjectSortBy>(),
                  ...ProjectSortBy.values.map((sort) {
                    final isSelected = sort == _sortBy;
                    IconData icon;
                    switch (sort) {
                      case ProjectSortBy.recentlyEdited:
                        icon = Icons.access_time_rounded;
                        break;
                      case ProjectSortBy.newest:
                        icon = Icons.fiber_new_rounded;
                        break;
                      case ProjectSortBy.name:
                        icon = Icons.sort_by_alpha_rounded;
                        break;
                      case ProjectSortBy.slides:
                        icon = Icons.view_carousel_rounded;
                        break;
                    }
                    return GlassMenuItem<ProjectSortBy>(
                      value: sort,
                      title: sort.label,
                      icon: icon,
                      isSelected: isSelected,
                    );
                  }),
                ],
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sort_rounded, size: 18, color: AppColors.textSecondary),
                      Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Grid/List toggle
              InkWell(
                onTap: () => setState(() => _isGridView = !_isGridView),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Icon(
                    _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT DESIGNS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${_filteredProjects.length} designs',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Project Grid Card
  // ==========================================
  Widget _buildProjectGridCard(CanvasProject project) {
    final coverSlideNum = (project.coverPageIndex + 1).toString().padLeft(2, '0');
    final formattedTime = _formatRelativeTime(project.updatedAt);

    return InkWell(
      onTap: () => _openProject(project),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Design Cover Thumbnail
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProjectCoverThumbnail(
                      project: project,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Cover badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 10, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 3),
                          Text(
                            'SLIDE $coverSlideNum',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Title and Options Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GlassPopupMenuButton<String>(
                  width: 230,
                  onSelected: (val) => _handleProjectAction(project, val),
                  itemBuilder: (context) => _buildProjectGlassMenu(project),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Metadata row (slides count + updated time)
            Row(
              children: [
                Text(
                  '${project.pages.length} ${project.pages.length == 1 ? 'slide' : 'slides'}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Project List Tile
  // ==========================================
  Widget _buildProjectListTile(CanvasProject project) {
    final formattedTime = _formatRelativeTime(project.updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _openProject(project),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: SizedBox(
            width: 54,
            height: 54,
            child: ProjectCoverThumbnail(
              project: project,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          title: Text(
            project.name,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${project.pages.length} slides • Edited $formattedTime',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          trailing: GlassPopupMenuButton<String>(
            width: 230,
            onSelected: (val) => _handleProjectAction(project, val),
            itemBuilder: (context) => _buildProjectGlassMenu(project),
          ),
        ),
      ),
    );
  }

  List<GlassMenuEntry<String>> _buildProjectGlassMenu(CanvasProject project) {
    return [
      GlassMenuHeader<String>(
        title: project.name,
        icon: Icons.layers_rounded,
      ),
      const GlassMenuDivider<String>(),
      const GlassMenuItem<String>(
        value: 'open',
        title: 'Open in Studio',
        subtitle: 'Edit canvas artboard',
        icon: Icons.auto_awesome_rounded,
        iconColor: Color(0xFFA78BFA),
        iconBackgroundColor: Color(0x338B5CF6),
      ),
      const GlassMenuItem<String>(
        value: 'cover',
        title: 'Change Cover Slide',
        subtitle: 'Select preview artboard',
        icon: Icons.star_rounded,
        iconColor: Color(0xFFFBBF24),
        iconBackgroundColor: Color(0x33FBBF24),
      ),
      const GlassMenuItem<String>(
        value: 'rename',
        title: 'Rename Project',
        icon: Icons.drive_file_rename_outline_rounded,
        iconColor: Color(0xFF38BDF8),
        iconBackgroundColor: Color(0x3338BDF8),
      ),
      const GlassMenuItem<String>(
        value: 'duplicate',
        title: 'Duplicate',
        icon: Icons.copy_rounded,
        iconColor: Color(0xFF94A3B8),
        iconBackgroundColor: Color(0x3394A3B8),
      ),
      const GlassMenuDivider<String>(),
      const GlassMenuItem<String>(
        value: 'delete',
        title: 'Delete Project',
        subtitle: 'Permanently remove',
        icon: Icons.delete_outline_rounded,
        isDestructive: true,
      ),
    ];
  }

  void _handleProjectAction(CanvasProject project, String action) {
    switch (action) {
      case 'open':
        _openProject(project);
        break;
      case 'cover':
        _pickProjectCover(project);
        break;
      case 'rename':
        _renameProject(project);
        break;
      case 'duplicate':
        _duplicateProject(project);
        break;
      case 'delete':
        _deleteProject(project);
        break;
    }
  }

  // ==========================================
  // Empty State
  // ==========================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.palette_outlined,
                size: 48,
                color: Color(0xFFA78BFA),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No designs created yet' : 'No matching designs found',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isEmpty
                  ? 'Start from a template above or create your own custom canvas'
                  : 'Try searching with a different keyword or clear your query',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showNewProjectModal,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create New Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

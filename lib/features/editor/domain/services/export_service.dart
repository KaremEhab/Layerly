import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:layerly/features/editor/domain/entities/canvas_page.dart';
import 'package:layerly/features/editor/domain/entities/canvas_project.dart';
import 'package:layerly/features/editor/presentation/widgets/canvas/page_renderer.dart';

enum ExportImageFormat { png, jpg }

class ExportResult {
  final bool success;
  final String? message;
  final String? filePath;
  final int count;

  const ExportResult({
    required this.success,
    this.message,
    this.filePath,
    this.count = 1,
  });
}

class ExportService {
  /// Rasterizes a [CanvasPage] cleanly into image bytes without selection boxes or guides.
  static Future<Uint8List> renderPageToBytes({
    required CanvasPage page,
    required CanvasProject project,
    double pixelRatio = 2.0,
    ExportImageFormat format = ExportImageFormat.png,
  }) async {
    final logicalSize = Size(page.width, page.height);

    // Build clean PageRenderer widget
    final widget = Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: SizedBox(
          width: logicalSize.width,
          height: logicalSize.height,
          child: PageRenderer(
            page: page,
            selectedLayerIds: const [],
            activeGuides: const [],
            activeSpacingMeasurements: const [],
            scale: 1.0,
            getComponentDefinition: (id) => project.components.cast().firstWhere(
                  (c) => c.id == id,
                  orElse: () => null,
                ),
          ),
        ),
      ),
    );

    final repaintBoundary = RenderRepaintBoundary();
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(logicalSize),
        devicePixelRatio: 1.0,
      ),
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: widget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final ui.Image image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to encode image to byte data');
    }

    return byteData.buffer.asUint8List();
  }

  /// Exports the current active page directly to the phone's Photo Gallery (iOS/Android)
  /// or Pictures/Layerly folder (Windows/macOS/Linux).
  static Future<ExportResult> exportPageToGallery({
    required CanvasPage page,
    required CanvasProject project,
    double pixelRatio = 2.0,
    ExportImageFormat format = ExportImageFormat.png,
    String album = 'Layerly',
  }) async {
    try {
      final bytes = await renderPageToBytes(
        page: page,
        project: project,
        pixelRatio: pixelRatio,
        format: format,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = page.name.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(RegExp(r'\s+'), '_');
      final extension = format == ExportImageFormat.jpg ? 'jpg' : 'png';
      final fileName = 'Layerly_${cleanName}_$timestamp';

      // 1. On Mobile (iOS / Android): Save to native Photo Gallery via Gal
      if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
        try {
          final hasAccess = await Gal.hasAccess(toAlbum: true);
          if (!hasAccess) {
            final granted = await Gal.requestAccess(toAlbum: true);
            if (!granted) {
              return const ExportResult(
                success: false,
                message: 'Photo library permission was denied. Please enable Photos access in Settings.',
              );
            }
          }

          await Gal.putImageBytes(
            bytes,
            name: fileName,
            album: album,
          );

          return ExportResult(
            success: true,
            message: 'Saved "${page.name}" directly to Photos ($album album)!',
          );
        } catch (e) {
          // If Gal fails, fallback to local directory saving
          if (kDebugMode) print('Gal mobile saving error, falling back: $e');
        }
      }

      // 2. Desktop (Windows / macOS / Linux) or mobile fallback: Save to Downloads / Documents
      final Directory? baseDir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();

      if (baseDir == null) {
        throw Exception('Could not determine local storage directory.');
      }

      final exportDir = Directory('${baseDir.path}${Platform.pathSeparator}Layerly');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final file = File('${exportDir.path}${Platform.pathSeparator}$fileName.$extension');
      await file.writeAsBytes(bytes);

      return ExportResult(
        success: true,
        filePath: file.path,
        message: 'Saved to ${file.path}',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Export failed: $e',
      );
    }
  }

  /// Exports all pages of the project to Photo Gallery (iOS/Android) or Pictures folder (Desktop).
  static Future<ExportResult> exportAllPagesToGallery({
    required CanvasProject project,
    double pixelRatio = 2.0,
    ExportImageFormat format = ExportImageFormat.png,
    String album = 'Layerly',
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      int savedCount = 0;
      final total = project.pages.length;
      final extension = format == ExportImageFormat.jpg ? 'jpg' : 'png';
      String? lastPath;

      final isMobile = !kIsWeb && (Platform.isIOS || Platform.isAndroid);

      if (isMobile) {
        final hasAccess = await Gal.hasAccess(toAlbum: true);
        if (!hasAccess) {
          final granted = await Gal.requestAccess(toAlbum: true);
          if (!granted) {
            return const ExportResult(
              success: false,
              message: 'Photo library permission was denied. Please enable Photos access in Settings.',
            );
          }
        }
      }

      final Directory? baseDir = !isMobile
          ? (await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory())
          : null;

      Directory? exportDir;
      if (baseDir != null) {
        exportDir = Directory('${baseDir.path}${Platform.pathSeparator}Layerly');
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
      }

      for (int i = 0; i < total; i++) {
        final page = project.pages[i];
        onProgress?.call(i + 1, total);

        final bytes = await renderPageToBytes(
          page: page,
          project: project,
          pixelRatio: pixelRatio,
          format: format,
        );

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final cleanName = page.name.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(RegExp(r'\s+'), '_');
        final fileName = 'Layerly_Slide_${i + 1}_${cleanName}_$timestamp';

        if (isMobile) {
          try {
            await Gal.putImageBytes(
              bytes,
              name: fileName,
              album: album,
            );
          } catch (_) {
            if (exportDir != null) {
              final file = File('${exportDir.path}${Platform.pathSeparator}$fileName.$extension');
              await file.writeAsBytes(bytes);
              lastPath = file.path;
            }
          }
        } else if (exportDir != null) {
          final file = File('${exportDir.path}${Platform.pathSeparator}$fileName.$extension');
          await file.writeAsBytes(bytes);
          lastPath = exportDir.path;
        }

        savedCount++;
      }

      final msg = isMobile
          ? 'Saved all $savedCount slides to Photos ($album album)!'
          : 'Saved all $savedCount slides to ${exportDir?.path ?? 'Pictures/Layerly'}!';

      return ExportResult(
        success: true,
        count: savedCount,
        filePath: lastPath,
        message: msg,
      );
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Export failed: $e',
      );
    }
  }
}


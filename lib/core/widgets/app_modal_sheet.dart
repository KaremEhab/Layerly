import 'package:flutter/material.dart';
import 'package:layerly/core/constants/app_colors.dart';

/// Opens a standardized, ultra-sleek bottom sheet designed for Layerly Studio.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: builder,
  );
}

/// Standardized container and layout for all Layerly bottom sheets.
class AppModalSheet extends StatelessWidget {
  final IconData? icon;
  final Gradient? iconGradient;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showDragHandle;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final double? maxHeightFactor;

  const AppModalSheet({
    super.key,
    this.icon,
    this.iconGradient,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding,
    this.showDragHandle = true,
    this.showCloseButton = true,
    this.onClose,
    this.maxHeightFactor,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 600;

    Widget content = SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(
          isCompact ? 12 : 24,
          0,
          isCompact ? 12 : 24,
          mediaQuery.viewInsets.bottom > 0 ? mediaQuery.viewInsets.bottom + 8 : 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF14131B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF2E2A42),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 36,
              offset: const Offset(0, 12),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              if (showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

              // 2. Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 14, 12),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: iconGradient ??
                              const LinearGradient(
                                colors: [Color(0xFF6C5CE7), Color(0xFF9B6CFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                    if (showCloseButton) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onClose ?? () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFF232032)),

              // 3. Sheet Body
              Flexible(
                child: Padding(
                  padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (maxHeightFactor != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * maxHeightFactor!,
        ),
        child: content,
      );
    }

    return content;
  }
}

/// Standardized action tile for modal menus.
class AppSheetActionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isDestructive;

  const AppSheetActionTile({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = isDestructive
        ? const Color(0xFFFF5C67)
        : (iconColor ?? Colors.white);
    final effectiveIconBgColor = isDestructive
        ? const Color(0xFFFF5C67).withValues(alpha: 0.15)
        : (iconBgColor ?? AppColors.surfaceSecondary);
    final effectiveTextColor = isDestructive
        ? const Color(0xFFFF5C67)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: isDestructive
            ? const Color(0xFFFF5C67).withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: effectiveIconBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDestructive
                        ? const Color(0xFFFF5C67).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: effectiveTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

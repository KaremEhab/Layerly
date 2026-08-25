import 'package:flutter/material.dart';
import 'package:layerly/core/constants/app_colors.dart';

/// Opens a standardized, ultra-sleek modal dialog designed for Layerly Studio.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: builder,
  );
}

/// Standardized container and layout for all Layerly dialogs.
class AppDialog extends StatelessWidget {
  final IconData? icon;
  final Gradient? iconGradient;
  final String title;
  final String? subtitle;
  final Widget? trailingHeader;
  final Widget content;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final String? confirmLabel;
  final IconData? confirmIcon;
  final VoidCallback? onConfirm;
  final bool isDestructiveConfirm;
  final List<Widget>? customActions;
  final double maxWidth;
  final bool showCloseButton;

  const AppDialog({
    super.key,
    this.icon,
    this.iconGradient,
    required this.title,
    this.subtitle,
    this.trailingHeader,
    required this.content,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.confirmLabel,
    this.confirmIcon,
    this.onConfirm,
    this.isDestructiveConfirm = false,
    this.customActions,
    this.maxWidth = 420,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161420),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF2E2A42),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 36,
                offset: const Offset(0, 16),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: iconGradient ??
                                (isDestructiveConfirm
                                    ? const LinearGradient(
                                        colors: [Color(0xFFFF5C67), Color(0xFFFF7675)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : const LinearGradient(
                                        colors: [Color(0xFF6C5CE7), Color(0xFF9B6CFF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: (isDestructiveConfirm
                                        ? const Color(0xFFFF5C67)
                                        : const Color(0xFF6C5CE7))
                                    .withValues(alpha: 0.35),
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
                      if (trailingHeader != null) ...[
                        const SizedBox(width: 8),
                        trailingHeader!,
                      ],
                      if (showCloseButton) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onCancel ?? () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFF232032)),

                // 2. Content
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: content,
                  ),
                ),

                // 3. Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: customActions ??
                        [
                          TextButton(
                            onPressed: onCancel ?? () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              cancelLabel,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (confirmLabel != null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: onConfirm,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isDestructiveConfirm
                                      ? const LinearGradient(
                                          colors: [Color(0xFFFF5C67), Color(0xFFFF7675)],
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF6C5CE7), Color(0xFF8B5CF6)],
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDestructiveConfirm
                                              ? const Color(0xFFFF5C67)
                                              : const Color(0xFF6C5CE7))
                                          .withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (confirmIcon != null) ...[
                                      Icon(confirmIcon, size: 14, color: Colors.white),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      confirmLabel!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

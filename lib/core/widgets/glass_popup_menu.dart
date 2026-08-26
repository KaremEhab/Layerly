import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Base class for items rendered inside a [GlassPopupMenuButton] or [GlassDropdownPill].
abstract class GlassMenuEntry<T> {
  const GlassMenuEntry();
}

/// An interactive selectable item within a [GlassPopupMenuButton].
class GlassMenuItem<T> extends GlassMenuEntry<T> {
  final T value;
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? trailing;
  final bool isDestructive;
  final bool isSelected;
  final VoidCallback? onTap;

  const GlassMenuItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.trailing,
    this.isDestructive = false,
    this.isSelected = false,
    this.onTap,
  });
}

/// A subtle frosted divider line between menu sections.
class GlassMenuDivider<T> extends GlassMenuEntry<T> {
  const GlassMenuDivider();
}

/// A non-interactive header label inside the menu.
class GlassMenuHeader<T> extends GlassMenuEntry<T> {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const GlassMenuHeader({
    required this.title,
    this.subtitle,
    this.icon,
  });
}

/// A modern, obsidian-frosted glass popup menu button.
class GlassPopupMenuButton<T> extends StatefulWidget {
  final Widget? child;
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final List<GlassMenuEntry<T>> Function(BuildContext context) itemBuilder;
  final ValueChanged<T>? onSelected;
  final double width;
  final double? maxHeight;
  final Offset offset;
  final String? tooltip;
  final EdgeInsetsGeometry padding;

  const GlassPopupMenuButton({
    super.key,
    this.child,
    this.icon,
    this.iconSize = 18,
    this.iconColor,
    required this.itemBuilder,
    this.onSelected,
    this.width = 230,
    this.maxHeight,
    this.offset = const Offset(0, 8),
    this.tooltip,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<GlassPopupMenuButton<T>> createState() => _GlassPopupMenuButtonState<T>();
}

class _GlassPopupMenuButtonState<T> extends State<GlassPopupMenuButton<T>> {
  OverlayEntry? _overlayEntry;

  void _showMenu() {
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _GlassMenuOverlay<T>(
        targetPosition: targetPosition,
        targetSize: targetSize,
        menuWidth: widget.width,
        menuMaxHeight: widget.maxHeight,
        offset: widget.offset,
        items: widget.itemBuilder(context),
        onSelected: (val) {
          _hideMenu();
          widget.onSelected?.call(val);
        },
        onDismiss: _hideMenu,
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child != null) {
      return InkWell(
        onTap: _showMenu,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      );
    }

    return IconButton(
      icon: Icon(
        widget.icon ?? Icons.more_vert_rounded,
        size: widget.iconSize,
        color: widget.iconColor ?? AppColors.textMuted,
      ),
      tooltip: widget.tooltip,
      padding: widget.padding,
      splashRadius: 20,
      onPressed: _showMenu,
    );
  }
}

/// A sleek pill dropdown selector that triggers the frosted acrylic glass popup menu.
class GlassDropdownPill<T> extends StatelessWidget {
  final T value;
  final String label;
  final TextStyle? labelStyle;
  final Widget? leading;
  final List<GlassMenuEntry<T>> Function(BuildContext context) items;
  final ValueChanged<T> onSelected;
  final double? width;
  final double height;
  final double menuWidth;
  final double? menuMaxHeight;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;

  const GlassDropdownPill({
    super.key,
    required this.value,
    required this.label,
    this.labelStyle,
    this.leading,
    required this.items,
    required this.onSelected,
    this.width,
    this.height = 38,
    this.menuWidth = 220,
    this.menuMaxHeight = 320,
    this.borderRadius,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return GlassPopupMenuButton<T>(
      width: menuWidth,
      maxHeight: menuMaxHeight,
      onSelected: onSelected,
      itemBuilder: items,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surfaceSecondary,
          borderRadius: radius,
          border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: labelStyle ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassMenuOverlay<T> extends StatefulWidget {
  final Offset targetPosition;
  final Size targetSize;
  final double menuWidth;
  final double? menuMaxHeight;
  final Offset offset;
  final List<GlassMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;

  const _GlassMenuOverlay({
    required this.targetPosition,
    required this.targetSize,
    required this.menuWidth,
    this.menuMaxHeight,
    required this.offset,
    required this.items,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  State<_GlassMenuOverlay<T>> createState() => _GlassMenuOverlayState<T>();
}

class _GlassMenuOverlayState<T> extends State<_GlassMenuOverlay<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Future<void> _handleSelect(T value) async {
    await _controller.reverse();
    widget.onSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Calculate left position (flip to left if overflows screen)
    double left = widget.targetPosition.dx + widget.offset.dx;
    if (left + widget.menuWidth > screenSize.width - 12) {
      left = widget.targetPosition.dx + widget.targetSize.width - widget.menuWidth - widget.offset.dx;
    }
    if (left < 12) left = 12;

    // Estimate rough menu height
    double rawHeight = widget.items.fold<double>(16.0, (acc, item) {
      if (item is GlassMenuItem<T>) return acc + (item.subtitle != null ? 52.0 : 42.0);
      if (item is GlassMenuDivider<T>) return acc + 10.0;
      if (item is GlassMenuHeader<T>) return acc + 36.0;
      return acc + 40.0;
    });

    final maxHeight = widget.menuMaxHeight ?? (screenSize.height * 0.48);
    final effectiveHeight = rawHeight.clamp(40.0, maxHeight);

    // Calculate top position (flip to above target if overflows screen bottom)
    double top = widget.targetPosition.dy + widget.targetSize.height + widget.offset.dy;
    if (top + effectiveHeight > screenSize.height - padding.bottom - 12) {
      top = widget.targetPosition.dy - effectiveHeight - widget.offset.dy;
    }
    if (top < padding.top + 12) {
      top = padding.top + 12;
    }

    return Stack(
      children: [
        // Fullscreen dismiss barrier
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleDismiss,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),

        // Floating Glass Popover
        Positioned(
          left: left,
          top: top,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                alignment: Alignment.topRight,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    width: widget.menuWidth,
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xF51A1728),
                          Color(0xF5120F1D),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 28,
                          spreadRadius: 2,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.items.map((entry) {
                          if (entry is GlassMenuDivider<T>) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            );
                          }

                          if (entry is GlassMenuHeader<T>) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                              child: Row(
                                children: [
                                  if (entry.icon != null) ...[
                                    Icon(entry.icon, size: 13, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      entry.title.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (entry is GlassMenuItem<T>) {
                            return _buildMenuItem(entry);
                          }

                          return const SizedBox.shrink();
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(GlassMenuItem<T> item) {
    final itemColor = item.isDestructive ? AppColors.danger : Colors.white;
    final iconColor = item.iconColor ?? (item.isDestructive ? AppColors.danger : const Color(0xFFA78BFA));
    final iconBg = item.iconBackgroundColor ??
        (item.isDestructive
            ? AppColors.danger.withValues(alpha: 0.15)
            : const Color(0xFF8B5CF6).withValues(alpha: 0.16));

    return InkWell(
      onTap: () {
        item.onTap?.call();
        _handleSelect(item.value);
      },
      borderRadius: BorderRadius.circular(12),
      hoverColor: Colors.white.withValues(alpha: 0.06),
      splashColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: item.isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (item.icon != null) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isDestructive
                        ? AppColors.danger.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.06),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 15,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: (item.titleStyle ?? TextStyle(
                      color: itemColor,
                      fontSize: 13,
                      fontWeight: item.isSelected ? FontWeight.w700 : FontWeight.w600,
                    )).copyWith(
                      color: itemColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      item.subtitle!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (item.isSelected)
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Color(0xFF8B5CF6),
              )
            else if (item.trailing != null)
              item.trailing!,
          ],
        ),
      ),
    );
  }
}

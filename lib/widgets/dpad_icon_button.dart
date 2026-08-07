import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';

class DpadIconButton extends StatefulWidget {
  final String debugLabel;
  final VoidCallback onPressed;
  final Widget icon;
  final double iconSize;
  final BoxConstraints? constraints;
  final bool showCircleBackground;
  final Color? focusedColor;
  final Color? unfocusedColor;
  final bool isSelected;
  final Color? selectedColor;
  final String? tooltip;
  final bool showCircleOnFocusOnly;
  final bool entry;

  const DpadIconButton({
    super.key,
    required this.debugLabel,
    required this.onPressed,
    required this.icon,
    this.iconSize = 24,
    this.constraints,
    this.showCircleBackground = false,
    this.focusedColor,
    this.unfocusedColor,
    this.isSelected = false,
    this.selectedColor,
    this.tooltip,
    this.entry = false,
    this.showCircleOnFocusOnly = true,
  });

  @override
  State<DpadIconButton> createState() => _DpadIconButtonState();
}

class _DpadIconButtonState extends State<DpadIconButton> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final DpadThemeData dpadTheme = DpadTheme.of(context);
    // When Dpad theme has no effects (empty list) the app is in mouse/touch
    // mode, not d-pad mode — skip focus highlight to avoid showing it on
    // every mouse click on desktop.
    final dpadMode = dpadTheme.effects.isNotEmpty;

    return DpadFocusable(
      debugLabel: widget.debugLabel,
      entry: widget.entry,
      child: const SizedBox(),
      builder: (context, state, child) {
        final useHighlight = widget.isSelected || (state.focused && dpadMode);
        final color = useHighlight
            ? (widget.selectedColor ?? widget.focusedColor ?? cs.primary)
            : (widget.unfocusedColor ?? cs.onSurfaceVariant);

        Widget button = IconButton(
          icon: widget.icon,
          iconSize: widget.iconSize,
          padding: EdgeInsets.zero,
          constraints:
              widget.constraints ??
              const BoxConstraints(minWidth: 36, minHeight: 36),
          color: color,
          onPressed: widget.onPressed,
          tooltip: widget.tooltip,
          style: IconButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
        );

        if (widget.showCircleBackground &&
            (!widget.showCircleOnFocusOnly || (state.focused && dpadMode))) {
          Color? bgColor;
          if (useHighlight) {
            bgColor = cs.secondaryContainer.withValues(
              alpha: state.focused ? 1.0 : 0.5,
            );
          }
          button = Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor ?? Colors.transparent,
            ),
            child: button,
          );
        }

        return button;
      },
    );
  }
}

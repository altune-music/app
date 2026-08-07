import 'package:flutter/material.dart';
import '../widgets/dpad_icon_button.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DpadIconButton(
      debugLabel: 'BackButton',
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      icon: const Icon(Icons.chevron_left),
      iconSize: 28,
      constraints: const BoxConstraints(),
    );
  }
}

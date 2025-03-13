import "package:flutter/material.dart";
import "package:kaiteki/di.dart";

class ToggleSubjectButton extends StatelessWidget {
  const ToggleSubjectButton({
    super.key,
    required this.value,
    this.onChanged,
  });

  final bool value;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      onPressed: onChanged,
      isSelected: value,
      icon: const Icon(Icons.short_text_rounded),
      selectedIcon: Icon(
        Icons.short_text_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      tooltip: value
          ? l10n.contentWarningButtonLabelDisable
          : l10n.contentWarningButtonLabelEnable,
    );
  }
}

import "package:flutter/material.dart";
import "package:kaiteki/di.dart";
import "package:kaiteki/preferences/app_experiment.dart";
import "package:kaiteki/preferences/app_preferences.dart";
import "package:kaiteki/theming/text_theme.dart";
import "package:kaiteki/ui/shared/emoji/emoji_widget.dart";
import "package:kaiteki_core/model.dart";

class ReactionButton extends ConsumerWidget {
  final Reaction reaction;
  final VoidCallback onPressed;

  const ReactionButton({
    super.key,
    required this.onPressed,
    required this.reaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dense = ref.watch(AppExperiment.denseReactions.provider);
    final emojiSize = dense ? 16.0 : 24.0;

    final reacted = reaction.includesMe;
    final theme = Theme.of(context);
    final backgroundColor = reacted ? theme.colorScheme.inverseSurface : null;

    final foregroundColor = reacted
        ? theme.colorScheme.onInverseSurface
        : theme.colorScheme.onSurfaceVariant;

    final textStyle = theme.ktkTextTheme?.countTextStyle ??
        DefaultKaitekiTextTheme(context).countTextStyle;

    var count = reaction.count;

    if (reacted) count--;

    final emoji = reaction.emoji;
    final emojiTitle = switch (emoji) {
      UnicodeEmoji() => emoji.short,
      _ => emoji.short,
    };
    final outlineColor = theme.colorScheme.outline;

    Widget widget = MaterialButton(
      color: backgroundColor,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: reacted ? BorderSide.none : BorderSide(color: outlineColor),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minWidth: emojiSize + 40,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DefaultTextStyle.merge(
            style: TextStyle(color: foregroundColor),
            child: EmojiWidget(
              emoji,
              size: emojiSize,
            ),
          ),
          if (ref.watch(showReactionCounts).value) ...[
            const SizedBox(width: 6),
            Text(
              reaction.count.toString(),
              style: textStyle.copyWith(color: foregroundColor),
            ),
          ],
        ],
      ),
    );

    if (emoji is CustomEmoji) {
      widget = Tooltip(
        message: emoji.short,
        child: widget,
      );
    }

    return Semantics(
      label: count >= 1 ? "$count $emojiTitle reactions" : null,
      excludeSemantics: true,
      child: widget,
    );
  }

  String _getEmojiText(Emoji emoji) {
    if (emoji is UnicodeEmoji) return emoji.emoji;
    return emoji.toString();
  }
}

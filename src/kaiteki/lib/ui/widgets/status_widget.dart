import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kaiteki/fediverse/model/attachment.dart';
import 'package:kaiteki/fediverse/model/post.dart';
import 'package:kaiteki/fediverse/model/user.dart';
import 'package:kaiteki/fediverse/model/visibility.dart';
import 'package:kaiteki/theming/app_themes/app_theme.dart';
import 'package:kaiteki/theming/theme_container.dart';
import 'package:kaiteki/ui/intents.dart';
import 'package:kaiteki/ui/shortcut_keys.dart';
import 'package:kaiteki/ui/widgets/attachments.dart';
import 'package:kaiteki/ui/widgets/posts/avatar_widget.dart';
import 'package:kaiteki/ui/widgets/posts/card_widget.dart';
import 'package:kaiteki/ui/widgets/posts/count_button.dart';
import 'package:kaiteki/ui/widgets/posts/interaction_event_bar.dart';
import 'package:kaiteki/ui/widgets/posts/reaction_row.dart';
import 'package:kaiteki/utils/extensions.dart';
import 'package:kaiteki/utils/extensions/duration.dart';
import 'package:kaiteki/utils/text/text_renderer.dart';
import 'package:kaiteki/utils/text/text_renderer_theme.dart';
import 'package:kaiteki/utils/utils.dart';
import 'package:mdi/mdi.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class StatusWidget extends StatelessWidget {
  final Post _post;
  final bool showParentPost;
  final bool showActions;

  const StatusWidget(
    this._post, {
    Key? key,
    this.showParentPost = true,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final container = Provider.of<ThemeContainer>(context);
    final theme = container.current;

    final rendererTheme = TextRendererTheme.fromContext(context);
    const authorTextStyle = TextStyle(fontWeight: FontWeight.bold);

    final content = _post.content;
    final l10n = AppLocalizations.of(context)!;

    if (_post.repeatOf != null) {
      return Column(
        children: [
          InteractionEventBar(
            icon: Mdi.repeat,
            text: l10n.postRepeated,
            color: theme.repeatColor,
            user: _post.author,
            userTextStyle: authorTextStyle,
          ),
          StatusWidget(_post.repeatOf!),
        ],
      );
    }

    InlineSpan renderedAuthor = TextRenderer(
      emojis: _post.author.emojis,
      theme: rendererTheme,
    ).renderFromHtml(context, _post.author.displayName);

    InlineSpan? renderedContent;
    if (content != null) {
      final renderer = TextRenderer(
        emojis: _post.emojis,
        theme: rendererTheme,
      );

      renderedContent = renderer.renderFromHtml(context, content);
    }

    return FocusableActionDetector(
      shortcuts: {
        ShortcutKeys.replyKeySet: ReplyIntent(),
        ShortcutKeys.repeatKeySet: RepeatIntent(),
        ShortcutKeys.favoriteKeySet: FavoriteIntent(),
        // ShortcutKeys.reactKeySet: ReactIntent(),
        ShortcutKeys.menuKeySet: MenuIntent(),
      },
      actions: {
        ReplyIntent: CallbackAction(onInvoke: (e) => reply(context, _post)),
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AvatarWidget(_post.author, size: 48),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MetaBar(
                    renderedAuthor: renderedAuthor,
                    authorTextStyle: authorTextStyle,
                    post: _post,
                    theme: theme,
                  ),

                  if (showParentPost && _post.replyToPostId != null)
                    ReplyBar(post: _post),

                  if (renderedContent != null) Text.rich(renderedContent),

                  if (_post.attachments != null)
                    AttachmentRow(
                      attachments: _post.attachments!.toList(growable: false),
                    ),

                  if (_post.previewCard != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: CardWidget(card: _post.previewCard!),
                    ),

                  if (_post.reactions.isNotEmpty)
                    ReactionRow(_post, _post.reactions),

                  if (showActions) InteractionBar(post: _post, theme: theme),
                  // ApplicationWidget(_post.application),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class MetaBar extends StatelessWidget {
  const MetaBar({
    Key? key,
    required this.renderedAuthor,
    required Post post,
    required this.theme,
    this.authorTextStyle,
  })  : _post = post,
        super(key: key);

  final InlineSpan renderedAuthor;
  final Post _post;
  final AppTheme theme;
  final TextStyle? authorTextStyle;

  @override
  Widget build(BuildContext context) {
    final secondaryText = _getSecondaryUserText(_post.author);
    final secondaryColor = Theme.of(context).disabledColor;
    final secondaryTextTheme = TextStyle(color: secondaryColor);

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: _equalUserName(_post.author) ? 0.0 : 6.0,
            children: [
              Text.rich(renderedAuthor, style: authorTextStyle),
              if (secondaryText != null)
                Text(
                  secondaryText,
                  style: secondaryTextTheme,
                  overflow: TextOverflow.fade,
                ),
            ],
          ),
        ),
        Tooltip(
          message: _post.postedAt.toString(),
          child: Text(
            DateTime.now().difference(_post.postedAt).toStringHuman(
                  context: context,
                ),
            style: secondaryTextTheme,
          ),
        ),
        // if (_post.visibility != null)
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Tooltip(
            message: _post.visibility.toHumanString(),
            child: Icon(
              _post.visibility.toIconData(),
              size: 20,
              color: secondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  String? _getSecondaryUserText(User user) {
    String? result;

    if (!_equalUserName(user)) {
      result = user.username;
    }

    if (user.host != null) {
      result = (result ?? '') + '@' + user.host!;
    }

    return result;
  }

  bool _equalUserName(User user) {
    return user.username.toLowerCase() == user.displayName.toLowerCase();
  }
}

class ReplyBar extends StatelessWidget {
  const ReplyBar({
    Key? key,
    this.textStyle,
    required this.post,
  }) : super(key: key);

  final TextStyle? textStyle;
  final Post post;

  @override
  Widget build(BuildContext context) {
    var themeContainer = Provider.of<ThemeContainer>(context);
    final disabledColor = Theme.of(context).disabledColor;
    final l10n = AppLocalizations.of(context)!;

    return Text.rich(
      TextSpan(
        style: textStyle,
        children: [
          // TODO: refactor the following widget pattern to a future "IconSpan"
          WidgetSpan(
            child: Icon(
              Mdi.share,
              size: Utils.getLocalFontSize(context) * 1.25,
              color: disabledColor,
            ),
          ),
          TextSpan(
            text: ' ' + l10n.replyTo + ' ',
            style: TextStyle(color: disabledColor),
          ),
          TextSpan(
            text: post.replyToAccountId,
            style: themeContainer.current.linkTextStyle,
          ),
        ],
      ),
    );
  }
}

class InteractionBar extends StatelessWidget {
  const InteractionBar({
    Key? key,
    required Post post,
    required this.theme,
  })  : _post = post,
        super(key: key);

  final Post _post;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    var openInBrowserAvailable = _post.externalUrl != null;
    final l10n = AppLocalizations.of(context)!;

    // Added Material for fixing bork with Hero *shrug*
    return Row(
      children: [
        CountButton(
          icon: const Icon(Icons.reply),
          count: _post.replyCount,
          buttonOnly: true,
          onTap: () => reply(context, _post),
          focusNode: FocusNode(skipTraversal: true),
        ),
        CountButton(
          icon: const Icon(Icons.repeat),
          count: _post.repeatCount,
          active: _post.repeated,
          activeColor: theme.repeatColor,
          focusNode: FocusNode(skipTraversal: true),
        ),
        CountButton(
          icon: const Icon(Mdi.starOutline),
          count: _post.likeCount,
          active: _post.liked,
          activeColor: theme.favoriteColor,
          activeIcon: const Icon(Icons.star),
          focusNode: FocusNode(skipTraversal: true),
        ),
        IconButton(
          icon: const Icon(Icons.insert_emoticon),
          onPressed: null,
          focusNode: FocusNode(skipTraversal: true),
        ),
        PopupMenuButton<VoidCallback>(
          icon: const Icon(Icons.more_horiz),
          onSelected: (callback) => callback.call(),
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                enabled: openInBrowserAvailable,
                child: ListTile(
                  title: Text(l10n.openInBrowserLabel),
                  leading: const Icon(Mdi.openInNew),
                  contentPadding: const EdgeInsets.all(0.0),
                  enabled: openInBrowserAvailable,
                ),
                value: () async {
                  await launch(_post.externalUrl!);
                },
              ),
            ];
          },
        ),
      ],
    );
  }
}

class AttachmentRow extends StatelessWidget {
  final List<Attachment> attachments;

  const AttachmentRow({
    Key? key,
    required this.attachments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var border = Theme.of(context).dividerColor;
    var borderRadius = BorderRadius.circular(8);

    return LimitedBox(
      maxHeight: 280,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var attachment in attachments)
            Flexible(
              fit: FlexFit.loose,
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  // TODO (theming): Implement pleroma attachment rounding
                  borderRadius: borderRadius,
                  border: Border.all(color: border, width: 1),
                ),
                child: getAttachmentWidget(attachment),
              ),
            ),
        ],
      ),
    );
  }
}

void reply(BuildContext context, Post post) {
  context.showPostDialog(replyTo: post);
}

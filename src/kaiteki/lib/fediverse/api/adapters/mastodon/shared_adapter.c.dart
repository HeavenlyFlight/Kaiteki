part of 'shared_adapter.dart';

Post toPost(mastodon.Status source) {
  return Post(
    source: source,
    content: source.content,
    postedAt: source.createdAt,
    nsfw: source.sensitive,
    subject: source.spoilerText,
    author: toUser(source.account),
    repeatOf: source.reblog != null ? toPost(source.reblog!) : null,
    // shouldn't be null because we currently expect the user to be signed in
    repeated: source.reblogged!,
    liked: source.favourited!,
    emojis: source.emojis.map(toEmoji),
    attachments: source.mediaAttachments.map(toAttachment),
    likeCount: source.favouritesCount,
    repeatCount: source.reblogsCount,
    replyCount: source.repliesCount,
    visibility: toVisibility(source.visibility),
    replyToAccountId: source.inReplyToAccountId,
    replyToPostId: source.inReplyToId,
    replyToUser: getRepliedUser(source),
    id: source.id,
    externalUrl: source.url,
    reactions: [], // TODO: add pleroma reactions?
  );
}

User? getRepliedUser(mastodon.Status status) {
  final mention = status.mentions.firstOrDefault((mention) {
    return mention.id == status.inReplyToAccountId;
  });

  if (mention == null) {
    return null;
  }

  return User(
    host: getHost(mention.account),
    username: mention.username,
    id: mention.id,
    displayName: mention.username,
    source: mention,
  );
}

Visibility toVisibility(String visibility) {
  const visibilityToString = {
    'public': Visibility.public,
    'private': Visibility.followersOnly,
    'direct': Visibility.direct,
    'unlisted': Visibility.unlisted,
  };

  return visibilityToString[visibility]!;
}

Attachment toAttachment(mastodon.Attachment attachment) {
  return Attachment(
    source: attachment,
    description: attachment.description,
    url: attachment.url,
    previewUrl: attachment.previewUrl,
    type: toAttachmentType(attachment.type),
  );
}

AttachmentType toAttachmentType(String type) {
  const attachmentTypeToString = {
    'image': AttachmentType.image,
    'video': AttachmentType.video,
    'audio': AttachmentType.audio,
    // 'gifv': AttachmentType.animated,
  };

  return attachmentTypeToString[type] ?? AttachmentType.file;
}

CustomEmoji toEmoji(mastodon.Emoji emoji) {
  return CustomEmoji(
    source: emoji,
    url: emoji.staticUrl,
    name: emoji.shortcode,
    aliases: emoji.tags ?? [],
  );
}

User toUser(mastodon.Account source) {
  return User(
    source: source,
    displayName: source.displayName,
    username: source.username,
    bannerUrl: source.header,
    avatarUrl: source.avatar,
    joinDate: source.createdAt,
    id: source.id,
    description: source.note,
    emojis: source.emojis.map(toEmoji),
    birthday: null, // Mastodon doesn't support this
    followerCount: source.followersCount,
    followingCount: source.followingCount,
    postCount: source.statusesCount,
    host: getHost(source.acct),
  );
}

String? getHost(String acct) {
  var split = acct.split('@');

  if (split.length > 1) return split.last;

  return null;
}

Instance toInstance(mastodon.Instance instance) {
  return Instance(
    source: instance,
    iconUrl: null,
    name: instance.title,
    backgroundUrl: instance.thumbnail,
  );
}

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:kaiteki_core/social.dart';
import 'package:uuid/uuid.dart';

import 'capabilities.dart';
import 'client.dart';
import 'extensions.dart';

const scopes = ['basic', 'write', 'offline_access'];
const consumerKey = 'FZlWlVPgJDmHF0fLssyJpoLqDmaxaGjcVlDW618dFVG61MvogO';
const consumerSecret = '6RTwNsXOfEZIc0avog23jAU6lMXhfVN7z11TQq0P3YRsOU5NSN';

class TumblrAdapter extends CentralizedBackendAdapter
    implements NotificationSupport, SearchSupport, LoginSupport, OAuthReceiver {
  final TumblrClient client;

  factory TumblrAdapter() {
    return TumblrAdapter.custom(TumblrClient());
  }

  TumblrAdapter.custom(this.client);

  @override
  FutureOr<void> applySecrets(
    ClientSecret? clientSecret,
    UserSecret userSecret,
  ) {
    super.applySecrets(clientSecret, userSecret);
    client.accessToken = userSecret.accessToken;
  }

  @override
  AdapterCapabilities get capabilities => const TumblrCapabilities();

  @override
  Future<User> getMyself() async {
    final response = await client.getUserInfo();
    return response.user.toKaiteki();
  }

  @override
  Future<Post> getPostById(String id) {
    // TODO: implement getPostById
    throw UnimplementedError();
  }

  @override
  Future<List<User>> getRepeatees(String id) {
    // TODO: implement getRepeatees
    throw UnimplementedError();
  }

  @override
  Future<List<Post>> getTimeline(
    TimelineType type, {
    TimelineQuery<String>? query,
    PostFilter? filter,
  }) async {
    final blogFields = [
      'name',
      'avatar',
      'title',
      'url',
      'uuid',
      '?followed',
      'theme',
      '?primary',
      '?paywall_access',
      'tumblrmart_accessories',
      'can_show_badges',
      '?live_now',
    ];

    switch (type) {
      case TimelineType.following:
        final response = await client.getDashboard(
          sinceId: query?.untilId,
          reblogInfo: true,
          notesInfo: true,
          npf: false,
          fields: {'blogs': blogFields},
        );

        return response.posts.map((e) => e.toKaiteki()).toList();

      default:
        throw UnsupportedError('Timeline type $type is not supported');
    }
  }

  @override
  Future<User> getUser(String username, [String? instance]) {
    return getUserById(username);
  }

  @override
  Future<User> getUserById(String id) async {
    final response = await client.getBlogInfo(id);
    return response.blog.toKaiteki();
  }

  @override
  final instance = const Instance(
    name: 'Tumblr',
  );

  @override
  Future<LoginResult> login(LoginContext context) async {
    final state = const Uuid().v4();

    return await context.requestOAuth!((url) async {
      final authorizationUrl = Uri.https(
        'tumblr.com',
        '/oauth2/authorize',
        {
          'response_type': 'code',
          'client_id': consumerKey,
          'redirect_uri': url.toString(),
          'scope': scopes.join(' '),
          'state': state,
        },
      );
      return (authorizationUrl, {"redirect_uri": url.toString()});
    });
  }

  @override
  Future<LoginResult> handleOAuth(
      Map<String, String> query, Map<String, String>? extra) async {
    final tokenResponse = await client.getToken(
      clientId: consumerKey,
      clientSecret: consumerSecret,
      code: query["code"]!,
      redirectUri: extra!["redirect_uri"]!,
    );

    client.accessToken = tokenResponse.accessToken;

    final userInfoResponse = await client.getUserInfo();

    return LoginSuccess(
      user: userInfoResponse.user.toKaiteki(),
      userSecret: (
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        userId: userInfoResponse.user.name,
      ),
      clientSecret: null,
    );
  }

  @override
  Future<User> lookupUser(String username, [String? host]) {
    // TODO: implement lookupUser
    throw UnimplementedError();
  }

  @override
  Future<Post> postStatus(PostDraft draft, {Post? parentPost}) {
    // TODO: implement postStatus
    throw UnimplementedError();
  }

  @override
  Future<void> repeatPost(String id) {
    // TODO: implement repeatPost
    throw UnimplementedError();
  }

  @override
  Future<void> unrepeatPost(String id) {
    // TODO: implement unrepeatPost
    throw UnimplementedError();
  }

  @override
  Future<Attachment> uploadAttachment(AttachmentDraft draft) {
    // TODO: implement uploadAttachment
    throw UnimplementedError();
  }

  @override
  Future<void> clearAllNotifications() {
    // TODO: implement clearAllNotifications
    throw UnimplementedError();
  }

  @override
  Future<void> markAllNotificationsAsRead() {
    // TODO: implement markAllNotificationsAsRead
    throw UnimplementedError();
  }

  @override
  Future<void> markNotificationAsRead(Notification notification) {
    // TODO: implement markNotificationAsRead
    throw UnimplementedError();
  }

  @override
  Future<SearchResults> search(String query) async {
    final response = await client.search(query);
    return SearchResults(
      posts: response.posts.map((e) => e.toKaiteki()).toList(),
    );
  }

  @override
  Future<List<String>> searchForHashtags(String query) {
    // TODO: implement searchForHashtags
    throw UnimplementedError();
  }

  @override
  Future<List<Post>> searchForPosts(String query) {
    // TODO: implement searchForPosts
    throw UnimplementedError();
  }

  @override
  Future<List<User>> searchForUsers(String query) {
    // TODO: implement searchForUsers
    throw UnimplementedError();
  }

  @override
  Future<Object?> resolveUrl(Uri url) {
    // TODO: implement resolveUrl
    throw UnimplementedError();
  }

  @override
  Future<List<Notification>> getNotifications({
    String? sinceId,
    String? untilId,
  }) {
    // TODO: implement getNotifications
    throw UnimplementedError();
  }

  @override
  Future<List<Post>> getPostsOfUserById(
    String id, {
    TimelineQuery<String>? query,
    PostFilter? filter,
  }) async {
    final response = await client.getBlogPosts(id);
    return response.posts.map((e) => e.toKaiteki()).toList();
  }

  @override
  Future<Iterable<Post>> getThread(String postId) {
    // TODO: implement getThread
    throw UnimplementedError();
  }

  @override
  Future<ProfileSettings> getProfileSettings() {
    // TODO: implement getProfileSettings
    throw UnimplementedError();
  }

  @override
  Future<void> setAvatar(XFile? image) {
    // TODO: implement setAvatar
    throw UnimplementedError();
  }

  @override
  Future<void> setBackground(XFile? image) {
    // TODO: implement setBackground
    throw UnimplementedError();
  }

  @override
  Future<void> setBanner(XFile? image) {
    // TODO: implement setBanner
    throw UnimplementedError();
  }

  @override
  Future<void> setProfileSettings(ProfileSettings settings) {
    // TODO: implement setProfileSettings
    throw UnimplementedError();
  }

  @override
  Future<void> deletePost(String id) {
    // TODO: implement deletePost
    throw UnimplementedError();
  }
}

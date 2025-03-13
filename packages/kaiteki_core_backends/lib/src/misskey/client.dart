import 'dart:async';
import 'dart:convert';

import 'package:fediverse_objects/misskey.dart' as misskey;
import 'package:http/http.dart'
    show MultipartFile, MultipartRequest, Request, Response;
import 'package:kaiteki_core/http.dart';
import 'package:kaiteki_core/utils.dart';
import 'package:logging/logging.dart';

import 'exception.dart';
import 'model/follow.dart';
import 'model/list.dart';
import 'model/mute.dart';
import 'requests/sign_in.dart';
import 'requests/timeline.dart';
import 'responses/check_session.dart';
import 'responses/create_app.dart';
import 'responses/create_note.dart';
import 'responses/emojis.dart';
import 'responses/generate_session.dart';
import 'responses/note_translate.dart';
import 'responses/signin.dart';
import 'responses/userkey.dart';

export 'requests/timeline.dart';

class MisskeyClient {
  static final _logger = Logger('MisskeyClient');
  late final KaitekiClient client;

  String? i;
  final String instance;

  MisskeyClient(this.instance) {
    client = KaitekiClient(
      baseUri: Uri(scheme: 'https', host: instance),
      checkResponse: _checkResponse,
      intercept: (request) {
        final i = this.i;
        if (i == null) return;

        if (request is Request) {
          // TODO(Craftplacer): we should avoid duplicate (de-)serialization.
          final map = request.bodyBytes.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(request.body) as JsonMap;
          map['i'] = i;
          request.body = jsonEncode(map);
          request.headers['Content-Type'] = 'application/json';
        } else if (request is MultipartRequest) {
          request.fields['i'] = i;
        }
      },
    );
  }

  Future<CreateAppResponse> createApp(
    String name,
    String description,
    List<String> permissions, {
    String? callbackUrl,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/app/create',
          body: {
            'name': name,
            'description': description,
            'permission': permissions,
            'callbackUrl': callbackUrl
          }.jsonBody,
        )
        .then(CreateAppResponse.fromJson.fromResponse);
  }

  Future<CreateNoteResponse> createNote({
    required String visibility,
    List<String>? visibleUserIds,
    String? text,
    String? cw,
    String? replyId,
    List<String>? fileIds = const [],
    ({
      List<String> choices,
      int? expiredAfter,
      int? expiresAt,
      bool multiple
    })? poll,
  }) async {
    // FIXME(Craftplacer): Properly parse Misskey create note response
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/create',
          body: <String, dynamic>{
            'visibility': visibility,
            'visibleUserIds': visibleUserIds ?? [],
            if (text != null) 'text': text,
            if (cw != null) 'cw': cw,
            if (replyId != null) 'replyId': replyId,
            if (fileIds?.isNotEmpty == true) 'fileIds': fileIds,
            if (poll != null)
              'poll': {
                'choices': poll.choices,
                if (poll.expiredAfter != null)
                  'expiredAfter': poll.expiredAfter,
                if (poll.expiresAt != null) 'expiresAt': poll.expiresAt,
                'multiple': poll.multiple,
              }
          }.jsonBody,
        )
        .then(CreateNoteResponse.fromJson.fromResponse);
  }

  Future<misskey.Note> showNote(String noteId) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/show',
          body: {'noteId': noteId}.jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponse);
  }

  Future<CreateNoteResponse> createRenote(String renoteId) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/create',
          body: {'renoteId': renoteId}.jsonBody,
        )
        .then(CreateNoteResponse.fromJson.fromResponse);
  }

  Future<GenerateSessionResponse> generateSession(
    String appSecret,
  ) async {
    return client
        .sendRequest(
          HttpMethod.post,
          '/api/auth/session/generate',
          body: {'appSecret': appSecret}.jsonBody,
        )
        .then(GenerateSessionResponse.fromJson.fromResponse);
  }

  Future<misskey.Page> getPage(String username, String name) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/pages/show',
          body: {'username': username, 'name': name}.jsonBody,
        )
        .then(misskey.Page.fromJson.fromResponse);
  }

  Future<UserkeyResponse> userkey(String appSecret, String token) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/auth/session/userkey',
          body: {'appSecret': appSecret, 'token': token}.jsonBody,
        )
        .then(UserkeyResponse.fromJson.fromResponse);
  }

  Future<misskey.User> showUser(String userId) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/show',
          body: {'userId': userId}.jsonBody,
        )
        .then(misskey.User.fromJson.fromResponse);
  }

  Future<misskey.User> showUserByName(
    String username, [
    String? instance,
  ]) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/show',
          body: {
            'username': username,
            if (instance != null) 'instance': instance,
          }.jsonBody,
        )
        .then(misskey.User.fromJson.fromResponse);
  }

  /// Gets the notes of the specified user.
  ///
  ///
  Future<List<misskey.Note>> showUserNotes(
    String userId, {
    bool? excludeNsfw,
    String? sinceId,
    String? untilId,
    bool? withFiles,
    bool? withReplies,
    bool? withRenotes,
    bool? withChannelNotes,
    int? limit,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/notes',
          body: {
            'userId': userId,
            if (sinceId != null) 'sinceId': sinceId,
            if (untilId != null) 'untilId': untilId,
            if (excludeNsfw != null) 'excludeNsfw': excludeNsfw,
            if (withFiles != null) 'withFiles': withFiles,
            if (withReplies != null) 'withReplies': withReplies,
            if (withRenotes != null) 'withRenotes': withRenotes,
            if (withChannelNotes != null) 'withChannelNotes': withChannelNotes,
          }.jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  Future<SignInResponse> signIn(MisskeySignInRequest request) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/signin',
          body: request.toJson().jsonBody,
        )
        .then(SignInResponse.fromJson.fromResponse);
  }

  Future<List<misskey.Note>> getTimeline(MisskeyTimelineRequest request) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/timeline',
          body: request.toJson().jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  // Have to implement checking nodeinfo for `disableLocalTimeline`
  Future<List<misskey.Note>> getLocalTimeline(
    MisskeyTimelineRequest request,
  ) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/local-timeline',
          body: request.toJson().jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  // Have to implement checking nodeinfo for `disableRecommendedTimeline`
  Future<List<misskey.Note>> getRecommendedTimeline(
    MisskeyTimelineRequest request,
  ) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/recommended-timeline',
          body: request.toJson().jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  // Have to implement checking nodeinfo for `disableLocalTimeline` (yes, local)
  Future<Iterable<misskey.Note>> getHybridTimeline(
    MisskeyTimelineRequest request,
  ) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/hybrid-timeline',
          body: request.toJson().jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  // Have to implement checking nodeinfo for `disableGlobalTimeline`
  Future<Iterable<misskey.Note>> getGlobalTimeline(
    MisskeyTimelineRequest request,
  ) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/global-timeline',
          body: request.toJson().jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  Future<void> _checkResponse(Response response) async {
    if (response.isSuccessful) return;

    // HACK(Craftplacer): I threw out the usual JSON deserialization pattern from Kaiteki because adding more error-prone code (that is Misskey's fucked API schemas) to error handling is just plain stupid.
    dynamic error;

    try {
      final json = jsonDecode(response.body) as JsonMap;
      error = json['error'];
    } catch (e, s) {
      _logger.warning('Failed to parse error JSON', e, s);
    }

    if (error is JsonMap) {
      throw MisskeyException(
        response.statusCode,
        misskey.Error.fromJson(error),
      );
    }

    throw HttpException.fromResponse(response);
  }

  /// Gets your account information.
  Future<misskey.User> getI() async {
    return client //
        .sendRequest(HttpMethod.post, 'api/i')
        .then(misskey.User.fromJson.fromResponse);
  }

  /// Reacts to the specified note.
  Future<void> createReaction(String noteId, String reaction) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/notes/reactions/create',
      body: {'noteId': noteId, 'reaction': reaction}.jsonBody,
    );
  }

  /// Removes the reaction from the specified note.
  Future<void> deleteReaction(String noteId) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/notes/reactions/delete',
      body: {'noteId': noteId}.jsonBody,
    );
  }

  Future<misskey.Meta> getMeta({bool detail = false}) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/meta',
          body: {'detail': detail}.jsonBody,
        )
        .then(misskey.Meta.fromJson.fromResponse);
  }

  Future<List<misskey.Note>> getConversation(
    String id, {
    int limit = 30,
    int offset = 0,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/conversation',
          body: {'noteId': id, 'limit': limit, 'offset': offset}.jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  Future<List<misskey.Note>> getNoteChildren(
    String id, {
    int limit = 30,
    String? sinceId,
    String? untilId,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/children',
          body: {
            'noteId': id,
            'limit': limit,
            if (sinceId != null) 'sinceId': sinceId,
            if (untilId != null) 'untilId': untilId,
          }.jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  Future<Iterable<misskey.MessagingMessage>> getMessagingHistory({
    int limit = 10,
    bool group = true,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/messaging/history',
          body: {'limit': limit, 'group': group}.jsonBody,
        )
        .then(misskey.MessagingMessage.fromJson.fromResponseList);
  }

  Future<Iterable<misskey.MessagingMessage>> getMessages({
    int limit = 10,
    bool markAsRead = true,
    required String? userId,
    required String? groupId,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/messaging/messages',
          body: {
            if (userId != null) 'userId': userId,
            if (groupId != null) 'groupId': groupId,
            'limit': limit,
            'markAsRead': markAsRead,
          }.jsonBody,
        )
        .then(misskey.MessagingMessage.fromJson.fromResponseList);
  }

  Future<misskey.DriveFile> createDriveFile(
    MultipartFile file, {
    String? folderId,
    String? name,
    String? comment,
    bool? isSensitive,
  }) {
    return client.sendMultipartRequest(
      HttpMethod.post,
      'api/drive/files/create',
      fields: <String, String>{
        if (folderId != null) 'folderId': folderId,
        if (name != null) 'name': name,
        if (comment != null) 'comment': comment,
        if (isSensitive != null) 'isSensitive': isSensitive.toString(),
      },
      files: [file],
    ).then(misskey.DriveFile.fromJson.fromResponse);
  }

  Future<CheckSessionResponse> checkSession(String session) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/miauth/$session/check',
        )
        .then(CheckSessionResponse.fromJson.fromResponse);
  }

  Future<List<misskey.Note>> getRenotes(String id) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/renotes',
          body: {'noteId': id}.jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  Future<void> markAllNotificationsAsRead() async {
    await client.sendRequest(
      HttpMethod.post,
      'api/notifications/mark-all-as-read',
    );
  }

  Future<List<misskey.Notification>> getNotifications({
    int? limit,
    bool? markAsRead,
    String? sinceId,
    String? untilId,
    bool? unreadOnly,
    // TODO(Craftplacer): add misskey notification types/filters
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/i/notifications',
          body: {
            if (limit != null) 'limit': limit,
            if (markAsRead != null) 'markAsRead': markAsRead,
            if (sinceId != null) 'sinceId': sinceId,
            if (untilId != null) 'untilId': untilId,
            if (unreadOnly != null) 'unreadOnly': unreadOnly,
          }.jsonBody,
        )
        .then(misskey.Notification.fromJson.fromResponseList);
  }

  Future<List<misskey.User>> searchUsers(
    String query, {
    int? offset,
    int? limit,
    String? origin,
    bool? detail,
  }) {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/search',
          body: {
            'query': query,
            if (offset != null) 'offset': offset,
            if (limit != null) 'limit': limit,
            if (origin != null) 'origin': origin,
            if (detail != null) 'detail': detail,
          }.jsonBody,
        )
        .then(misskey.User.fromJson.fromResponseList);
  }

  Future<List<misskey.Note>> searchNotes(
    String query, {
    String? sinceId,
    String? untilId,
    int? limit,
    int? offset,
    String? host,
    String? userId,
    String? channelId,
  }) {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/search',
          body: {
            'query': query,
            if (sinceId != null) 'sinceId': sinceId,
            if (untilId != null) 'untilId': untilId,
            if (limit != null) 'limit': limit,
            if (offset != null) 'offset': offset,
            if (host != null) 'host': host,
            if (userId != null) 'userId': userId,
            if (channelId != null) 'channelId': channelId,
          }.jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  Future<List<MisskeyList>> listLists() async {
    return client
        .sendRequest(HttpMethod.post, 'api/users/lists/list')
        .then(MisskeyList.fromJson.fromResponseList);
  }

  Future<MisskeyList> updateList(String listId, String name) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/lists/update',
          body: {'listId': listId, 'name': name}.jsonBody,
        )
        .then(MisskeyList.fromJson.fromResponse);
  }

  Future<MisskeyList> createList(String name) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/lists/create',
          body: {'name': name}.jsonBody,
        )
        .then(MisskeyList.fromJson.fromResponse);
  }

  Future<MisskeyList> showList(String listId) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/lists/show',
          body: {'listId': listId}.jsonBody,
        )
        .then(MisskeyList.fromJson.fromResponse);
  }

  Future<void> pullFromList(String listId, String userId) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/users/lists/pull',
      body: {'listId': listId, 'userId': userId}.jsonBody,
    );
  }

  Future<void> pushToList(String listId, String userId) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/users/lists/push',
      body: {'listId': listId, 'userId': userId}.jsonBody,
    );
  }

  Future<void> deleteList(String listId) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/users/lists/delete',
      body: {'listId': listId}.jsonBody,
    );
  }

  Future<List<misskey.Note>> getUserListTimeline(
    String listId,
    MisskeyTimelineRequest request,
  ) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/user-list-timeline',
          body: {'listId': listId, ...request.toJson()}.jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  Future<List<misskey.User>> showUsers(Set<String> userIds) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/show',
          body: {'userIds': userIds.toList()}.jsonBody,
        )
        .then(misskey.User.fromJson.fromResponseList);
  }

  Future<List<MisskeyFollow>> getUserFollowing(
    String userId, {
    String? sinceId,
    String? untilId,
    int? limit,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/following',
          body: {
            'userId': userId,
            if (sinceId != null) 'sinceId': sinceId,
            if (untilId != null) 'untilId': untilId,
            if (limit != null) 'limit': limit,
          }.jsonBody,
        )
        .then(MisskeyFollow.fromJson.fromResponseList);
  }

  Future<List<MisskeyFollow>> getUserFollowers(
    String userId, {
    String? sinceId,
    String? untilId,
    int? limit,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/followers',
          body: {
            'userId': userId,
            if (sinceId != null) 'sinceId': sinceId,
            if (untilId != null) 'untilId': untilId,
            if (limit != null) 'limit': limit,
          }.jsonBody,
        )
        .then(MisskeyFollow.fromJson.fromResponseList);
  }

  Future<NoteTranslateResponse> translateNote(
    String noteId,
    String targetLang,
  ) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/translate',
          body: {'noteId': noteId, 'targetLang': targetLang}.jsonBody,
        )
        .then(NoteTranslateResponse.fromJson.fromResponse);
  }

  Future<EmojisResponse> getEmojis() async => client
      .sendRequest(HttpMethod.post, 'api/emojis')
      .then(EmojisResponse.fromJson.fromResponse);

  Future<List<misskey.User>> searchUsersByUsernameAndHost(
    String username,
    String? host, {
    bool detail = true,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/users/search-by-username-and-host',
          body: {
            'username': username,
            if (host != null) 'host': host,
            'detail': detail,
          }.jsonBody,
        )
        .then(misskey.User.fromJson.fromResponseList);
  }

  Future<List<Mute>> getMutedAccounts(
    String? sinceId,
    String? untilId, {
    int limit = 30,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/mute/list',
          body: {
            'limit': limit,
            if (sinceId != null) 'sinceId': sinceId,
            if (untilId != null) 'untilId': untilId,
          }.jsonBody,
        )
        .then(Mute.fromJson.fromResponseList);
  }

  Future<void> muteUser(String userId, {int? expiresAt}) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/mute/create',
      body: {'userId': userId, if (expiresAt != null) 'expiresAt': expiresAt}
          .jsonBody,
    );
  }

  Future<void> unmuteUser(String userId) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/mute/delete',
      body: {
        'userId': userId,
      }.jsonBody,
    );
  }

  // TODO(Craftplacer): Misskey actually does return something -- UserLite?
  Future<void> followUser(String id) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/following/create',
      body: {'userId': id}.jsonBody,
    );
  }

  // TODO(Craftplacer): Misskey actually does return something -- UserLite?
  Future<void> unfollowUser(String id) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/following/delete',
      body: {'userId': id}.jsonBody,
    );
  }

  Future<List<misskey.FollowingRequest>> getFollowingRequests() async {
    return client
        .sendRequest(HttpMethod.post, 'api/following/requests/list')
        .then(misskey.FollowingRequest.fromJson.fromResponseList);
  }

  Future<void> acceptFollowRequest(String userId) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/following/requests/accept',
      body: {'userId': userId}.jsonBody,
    );
  }

  Future<void> rejectFollowRequest(String userId) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/following/requests/reject',
      body: {'userId': userId}.jsonBody,
    );
  }

  Future<List<misskey.Announcement>> getAnnouncements() async {
    return client
        .sendRequest(HttpMethod.post, 'api/announcements')
        .then(misskey.Announcement.fromJson.fromResponseList);
  }

  Future<List<String>> searchHashtags(String query) async {
    return client
        .sendRequest(
      HttpMethod.post,
      'api/hashtags/search',
      body: {'query': query}.jsonBody,
    )
        .then((response) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<String>();
    });
  }

  Future<List<misskey.Note>> searchNotesByTag(
    String hashtag, {
    String? sinceId,
    String? untilId,
    int? limit,
  }) async {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/notes/search-by-tag',
          body: {'tag': hashtag}.jsonBody,
        )
        .then(misskey.Note.fromJson.fromResponseList);
  }

  Future<void> createFavorite(String noteId) {
    return client.sendRequest(
      HttpMethod.post,
      'api/notes/favorites/create',
      body: {'noteId': noteId}.jsonBody,
    );
  }

  Future<void> deleteFavorite(String noteId) {
    return client.sendRequest(
      HttpMethod.post,
      'api/notes/favorites/delete',
      body: {'noteId': noteId}.jsonBody,
    );
  }

  Future<List<misskey.Favorite>> getFavorites({
    String? sinceId,
    String? untilId,
    int? limit,
  }) {
    return client
        .sendRequest(
          HttpMethod.post,
          'api/i/favorites',
          body: {
            if (sinceId != null) 'sinceId': sinceId,
            if (untilId != null) 'untilId': untilId,
            if (limit != null) 'limit': limit,
          }.jsonBody,
        )
        .then(misskey.Favorite.fromJson.fromResponseList);
  }

  Future<void> reportAbuse(String userId, String comment) async {
    await client.sendRequest(
      HttpMethod.post,
      'api/users/report-abuse',
      body: {'userId': userId, 'comment': comment}.jsonBody,
    );
  }

  Future<void> deleteNote(String noteId) {
    return client.sendRequest(
      HttpMethod.post,
      'api/notes/delete',
      body: {'noteId': noteId}.jsonBody,
    );
  }
}

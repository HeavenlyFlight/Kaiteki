import "package:kaiteki/fediverse/model/adapted_entity.dart";
import "package:kaiteki/fediverse/model/user/user.dart";

class Instance<T> extends AdaptedEntity<T> {
  final String name;
  final Uri? iconUrl;
  final Uri? mascotUrl;
  final Uri? backgroundUrl;

  final String? description;

  /// How many posts were made on this instance;
  final int? postCount;

  /// How many users are registered on this instance;
  final int? userCount;

  final User? administrator;

  const Instance({
    super.source,
    required this.name,
    this.iconUrl,
    this.backgroundUrl,
    this.mascotUrl,
    this.postCount,
    this.userCount,
    this.description,
    this.administrator,
  });
}

import 'package:json_annotation/json_annotation.dart';
import 'package:kaiteki_core/utils.dart';

part 'marker.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Marker {
  final String lastReadId;
  final int version;
  final DateTime updatedAt;

  const Marker({
    required this.lastReadId,
    required this.version,
    required this.updatedAt,
  });

  factory Marker.fromJson(JsonMap json) => _$MarkerFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class MarkerResponse {
  final Marker? notifications;
  final Marker? home;

  const MarkerResponse({this.notifications, this.home});

  factory MarkerResponse.fromJson(JsonMap json) =>
      _$MarkerResponseFromJson(json);
}

enum MarkerTimeline { home, notifications }

import 'package:equatable/equatable.dart';

import 'user.dart';

class UserHandle extends Equatable {
  final String username;
  final String host;

  const UserHandle(this.username, this.host);

  factory UserHandle.fromUser(User user) {
    return UserHandle(user.username, user.host);
  }

  @override
  List<Object?> get props => [username, host];

  @override
  String toString([bool leadingAt = true]) {
    final buffer = StringBuffer();
    if (leadingAt) buffer.write('@');
    buffer.writeAll([username, '@', host]);
    return buffer.toString();
  }
}

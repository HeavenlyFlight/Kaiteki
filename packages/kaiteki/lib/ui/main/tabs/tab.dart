import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:kaiteki/di.dart";
import "package:kaiteki/fediverse/services/notifications.dart";
import "package:kaiteki/ui/shared/common.dart";
import "package:kaiteki/utils/extensions.dart";
import "package:kaiteki_core/kaiteki_core.dart";
import "package:kaiteki_l10n/kaiteki_l10n.dart";

part "chats.dart";
part "explore.dart";
part "home.dart";
part "notifications.dart";

enum MainScreenTabType<T extends MainScreenTab> {
  home(
    Icon(Icons.home_outlined),
    Icon(Icons.home),
    _HomeMainScreenTab(),
  ),
  notifications(
    Icon(Icons.notifications_none),
    Icon(Icons.notifications_rounded),
    _NotificationsMainScreenTab(),
  ),
  chats(
    Icon(Icons.forum_outlined),
    Icon(Icons.forum_rounded),
    _ChatsMainScreenTab(),
  ),
  explore(
    Icon(Icons.explore_outlined),
    Icon(Icons.explore_rounded),
    _ExploreMainScreenTab(),
  );

  final T? tab;
  final Widget icon;
  final Widget selectedIcon;

  const MainScreenTabType(this.icon, this.selectedIcon, [this.tab]);

  String getLabel(KaitekiLocalizations localizations) {
    return switch (this) {
      MainScreenTabType.home => localizations.homeTab,
      MainScreenTabType.notifications => localizations.notificationsTab,
      MainScreenTabType.chats => localizations.chatsTab,
      MainScreenTabType.explore => "Explore",
    };
  }
}

sealed class MainScreenTab {
  const MainScreenTab();

  FloatingActionButtonLocation? get fabLocation => null;

  Widget? buildFab(BuildContext context, WidgetRef ref) => null;

  int? fetchUnreadCount(WidgetRef ref) => null;

  bool isAvailable(BackendAdapter adapter) => true;
}

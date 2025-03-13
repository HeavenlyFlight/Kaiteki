import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:kaiteki/di.dart";
import "package:kaiteki/ui/main/tabs/tab.dart";
import "package:kaiteki/ui/shared/badge.dart";
import "package:kaiteki/utils/extensions.dart";

class MainScreenNavigationRail extends ConsumerWidget {
  final List<MainScreenTabType> tabTypes;
  final int currentIndex;
  final ValueChanged<int>? onChangeIndex;
  final Color? backgroundColor;

  const MainScreenNavigationRail({
    super.key,
    required this.tabTypes,
    required this.currentIndex,
    this.onChangeIndex,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return NavigationRail(
      backgroundColor: backgroundColor,
      selectedIndex: currentIndex,
      onDestinationSelected: onChangeIndex,
      labelType: NavigationRailLabelType.all,
      leading: FloatingActionButton(
        backgroundColor: theme.colorScheme.tertiaryContainer,
        foregroundColor: theme.colorScheme.onTertiaryContainer,
        elevation: 0,
        onPressed: () => context.pushNamed(
          "compose",
          pathParameters: ref.accountRouterParams,
        ),
        tooltip: context.l10n.composeButtonLabel,
        heroTag: const ValueKey("navigation rail"),
        child: const Icon(Icons.edit_rounded),
      ),
      destinations: _buildDestinations(context, ref).toList(),
    );
  }

  Iterable<NavigationRailDestination> _buildDestinations(
    BuildContext context,
    WidgetRef ref,
  ) {
    return tabTypes.map((type) {
      final unreadCount = type.tab?.fetchUnreadCount.call(ref) ?? 0;

      return NavigationRailDestination(
        icon: KtkBadge(
          count: unreadCount,
          child: type.icon,
        ),
        selectedIcon: KtkBadge(
          count: unreadCount,
          child: type.selectedIcon,
        ),
        label: Text(type.getLabel(context.l10n)),
      );
    });
  }
}

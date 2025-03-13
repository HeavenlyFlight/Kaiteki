import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:kaiteki/di.dart";
import "package:kaiteki/ui/shared/error_landing_widget.dart";
import "package:kaiteki/ui/shared/posts/user_list_dialog.dart";
import "package:kaiteki/ui/shared/users/user_card.dart";
import "package:kaiteki/utils/extensions.dart";
import "package:kaiteki_core/social.dart";
import "package:kaiteki_core/utils.dart";

class UserSliver extends ConsumerStatefulWidget {
  final bool wide;
  final String userId;
  final bool showFollowing;

  const UserSliver.followers({
    super.key,
    this.wide = false,
    required this.userId,
  }) : showFollowing = false;

  const UserSliver.following({
    super.key,
    this.wide = false,
    required this.userId,
  }) : showFollowing = true;

  @override
  ConsumerState createState() => UserSliverState();
}

class UserSliverState extends ConsumerState<UserSliver> {
  final PagingController<String?, User> _controller = PagingController(
    firstPageKey: null,
  );

  late ProviderSubscription<BackendAdapter> _subscription;

  Future<PaginatedList<String?, User>> Function(String?) get _source {
    final adapter = _subscription.read() as FollowSupport;

    if (widget.showFollowing) {
      return (id) => adapter.getFollowing(widget.userId, untilId: id);
    } else {
      return (id) => adapter.getFollowers(widget.userId, untilId: id);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller.addPageRequestListener((id) async {
      try {
        final pagination = await _source(id);

        if (!mounted) return;

        if (pagination.data.isEmpty) {
          _controller.appendLastPage(pagination.data);
        } else {
          _controller.appendPage(pagination.data, pagination.next);
        }
      } catch (e, s) {
        if (mounted) _controller.error = (e, s);
      }
    });

    _subscription = ref.listenManual(
      adapterProvider,
      (_, __) => _controller.refresh(),
    );
  }

  @override
  void didUpdateWidget(covariant UserSliver oldWidget) {
    if (widget.userId != oldWidget.userId ||
        widget.showFollowing != oldWidget.showFollowing) {
      _controller.refresh();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void refresh() {
    _controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wide) {
      return PagedSliverGrid(
        pagingController: _controller,
        builderDelegate: PagedChildBuilderDelegate<User>(
          itemBuilder: (context, item, index) {
            return UserCard(item);
          },
          firstPageErrorIndicatorBuilder: (context) {
            return Center(
              child: ErrorLandingWidget(_controller.error as TraceableError),
            );
          },
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
      );
    }

    return PagedSliverList<dynamic, User>.separated(
      pagingController: _controller,
      builderDelegate: PagedChildBuilderDelegate<User>(
        itemBuilder: (context, item, index) {
          return widget.wide
              ? UserCard(item)
              : UserListTile(
                  user: item,
                  onPressed: () => context.showUser(item, ref),
                );
        },
        animateTransitions: true,
        firstPageErrorIndicatorBuilder: (context) {
          return Center(
            child: ErrorLandingWidget(_controller.error as TraceableError),
          );
        },
        noMoreItemsIndicatorBuilder: (context) {
          final l10n = context.l10n;
          return Align(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                l10n.noMorePosts,
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ),
          );
        },
      ),
      separatorBuilder: _buildSeparator,
    );
  }

  Widget _buildSeparator(BuildContext context, int index) {
    return const Divider(height: 1);
  }
}

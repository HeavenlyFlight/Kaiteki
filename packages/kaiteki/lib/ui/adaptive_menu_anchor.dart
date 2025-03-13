import "package:flutter/material.dart";
import "package:kaiteki/ui/shared/common.dart";
import "package:kaiteki_core/utils.dart";

class AdaptiveMenu extends StatelessWidget {
  final Function(BuildContext context, VoidCallback onTap)? builder;
  final List<Widget> Function(
    BuildContext context,
    VoidCallback? onClose,
  ) itemBuilder;

  const AdaptiveMenu({
    super.key,
    required this.itemBuilder,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: builder.andThen(
        (builder) => (context, controller, _) {
          return builder(
            context,
            () => _onTap(context, controller),
          );
        },
      ),
      menuChildren: itemBuilder(context, null),
      child: const Icon(Icons.more_vert_rounded),
    );
  }

  Future<void> _onTap(BuildContext context, MenuController controller) async {
    if (WindowWidthSizeClass.fromContext(context) >
        WindowWidthSizeClass.compact) {
      controller.open();
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            dragHandleInset,
            ...itemBuilder(
              context,
              () => Navigator.of(context).maybePop(),
            ),
          ],
        );
      },
    );
  }
}

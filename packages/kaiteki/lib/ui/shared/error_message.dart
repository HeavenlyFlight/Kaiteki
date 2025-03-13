import "package:flutter/material.dart";
import "package:kaiteki/utils/extensions.dart";
import "package:kaiteki_core/utils.dart";

class ErrorMessageWidget extends StatelessWidget {
  final TraceableError error;

  const ErrorMessageWidget(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Row(
      children: [
        Flexible(
          child: Text(
            error.toString(),
            style: TextStyle(color: color),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.info_outline,
            color: color,
            size: 20,
          ),
          splashRadius: 16,
          onPressed: () => context.showExceptionDialog(error),
        ),
      ],
    );
  }
}

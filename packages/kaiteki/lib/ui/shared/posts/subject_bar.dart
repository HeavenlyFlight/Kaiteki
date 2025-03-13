import "package:flutter/material.dart";

class SubjectBar extends StatelessWidget {
  final String subject;
  final bool collapsed;
  final VoidCallback? onTap;

  const SubjectBar({
    super.key,
    required this.subject,
    required this.collapsed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            subject,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: collapsed
              ? const Icon(Icons.expand_less_rounded)
              : const Icon(Icons.expand_more_rounded),
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
        ),
        if (!collapsed)
          const Column(
            children: [
              Divider(height: 1),
              SizedBox(height: 8),
            ],
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kaiteki/ui/widgets/layout/form_widget.dart';
import 'package:mdi/mdi.dart';

class AccountRequiredScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: FormWidget(
          padding: const EdgeInsets.all(24),
          builder: (context, fillsPage) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.welcome, textScaleFactor: 3),
              Text(l10n.accountRequiredToContinue),
              Expanded(
                child: Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Mdi.accountPlus),
                    label: Text(l10n.addAccountButtonLabel),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.comfortable,
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 28,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pushNamed("/login"),
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed("/settings");
                    },
                    child: Text(l10n.settings),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.comfortable,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

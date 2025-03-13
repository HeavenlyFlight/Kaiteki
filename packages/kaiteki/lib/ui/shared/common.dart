import "package:flutter/material.dart";
import "package:kaiteki/di.dart";
import "package:kaiteki_l10n/kaiteki_l10n.dart";
import "package:kaiteki_l10n/src/localizations_en.dart";
import "package:kaiteki_ui/kaiteki_ui.dart";
import "package:material_color_utilities/material_color_utilities.dart";

export "package:kaiteki/common.dart";
export "package:kaiteki_ui/kaiteki_ui.dart";

final systemColorSchemeProvider = Provider<ColorSchemeBundle?>((_) => null);

final _mouseTrackerProvider = ChangeNotifierProvider((_) {
  return WidgetsBinding.instance.mouseTracker;
});

final pointingDeviceProvider = Provider<PointingDevice>(
  (ref) {
    return ref.watch(
      _mouseTrackerProvider.select(
        (mouseTracker) {
          return mouseTracker.mouseIsConnected
              ? PointingDevice.mouse
              : PointingDevice.touch;
        },
      ),
    );
  },
  dependencies: [_mouseTrackerProvider],
);

enum PointingDevice { mouse, touch }

const kBullet = "•";

const kEmojiTextStyle = TextStyle(
  fontFamily: "Noto Color Emoji",
  fontFamilyFallback: ["Segoe UI Emoji"],
);

const kAppBarActionsSpacer = SizedBox(width: 8);

typedef LocalizableStringBuilder = String Function(BuildContext context);

const centeredCircularProgressIndicator = Center(
  child: circularProgressIndicator,
);

const circularProgressIndicator = CircularProgressIndicator.adaptive(
  strokeCap: StrokeCap.round,
);

/// A [SizedBox] with a height of 26, which is the default height of a
/// bottom sheet drag handle. This is used to inset the content of a
/// bottom sheet in case the drag handle is not used.
const dragHandleInset = SizedBox(height: 26);

Future<void> showTextAlert(BuildContext context, String title, String body) {
  return showDialog(
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          child: Text(context.materialL10n.okButtonLabel),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
    context: context,
  );
}

CustomColorPalette createCustomColorPalette(
  Color color,
  Brightness brightness,
) {
  final hct = Hct.fromInt(color.value);
  final palette = TonalPalette.of(hct.hue, hct.chroma);
  return brightness == Brightness.light
      ? CustomColorPalette.fromLight(palette)
      : CustomColorPalette.fromDark(palette);
}

class CustomColorPalette {
  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;

  CustomColorPalette(
    this.color,
    this.onColor,
    this.colorContainer,
    this.onColorContainer,
  );

  factory CustomColorPalette.fromLight(TonalPalette palette) {
    return CustomColorPalette(
      Color(palette.get(40)),
      Color(palette.get(100)),
      Color(palette.get(90)),
      Color(palette.get(10)),
    );
  }

  factory CustomColorPalette.fromDark(TonalPalette palette) {
    return CustomColorPalette(
      Color(palette.get(80)),
      Color(palette.get(20)),
      Color(palette.get(30)),
      Color(palette.get(90)),
    );
  }
}

enum EmphasisColor { high, medium, disabled }

extension ThemeDataExtension on ThemeData {
  @Deprecated("This method is not based on any proper Material guideline.")
  Color getEmphasisColor(EmphasisColor emphasis) {
    return switch (emphasis) {
      EmphasisColor.high => colorScheme.onSurface,
      EmphasisColor.medium => colorScheme.onSurfaceVariant,
      EmphasisColor.disabled => colorScheme.onSurface.withOpacity(.38),
    };
  }
}

class ContentColor extends StatelessWidget {
  final Widget child;
  final Color color;

  const ContentColor({super.key, required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return IconTheme.merge(
      data: IconThemeData(color: color),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: color),
        child: child,
      ),
    );
  }
}

String? getLocaleName(Locale locale) {
  final languageName = lookupKaitekiLocalizations(locale).languageName;
  final isEnglish = locale == const Locale("en");
  final isDefaultLanguageName =
      languageName == KaitekiLocalizationsEn().languageName;

  if (isDefaultLanguageName && !isEnglish) return null;
  return languageName;
}

typedef ThemeSet = ({
  ThemeData theme,
  ThemeData darkTheme,
  ThemeData highContrastTheme,
  ThemeData highContrastDarkTheme,
});

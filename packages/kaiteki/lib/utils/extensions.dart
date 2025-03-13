import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:html/dom.dart";
import "package:kaiteki/di.dart";
import "package:kaiteki/model/auth/account_key.dart";
import "package:kaiteki_core/kaiteki_core.dart";

export "package:kaiteki/text/rendering_extensions.dart";
export "package:kaiteki/utils/extensions/build_context.dart";
export "package:kaiteki/utils/extensions/duration.dart";
export "package:kaiteki/utils/extensions/enum.dart";
export "package:kaiteki/utils/extensions/iterable.dart";
export "package:kaiteki/utils/extensions/string.dart";

extension ObjectExtensions<T> on T? {
  T inlineBang(String description) {
    final value = this;
    if (value == null) throw Exception(description);
    return value;
  }
}

extension BrightnessExtensions on Brightness {
  Brightness get inverted {
    return switch (this) {
      Brightness.dark => Brightness.light,
      Brightness.light => Brightness.dark
    };
  }

  SystemUiOverlayStyle get systemUiOverlayStyle {
    return switch (this) {
      Brightness.dark => SystemUiOverlayStyle.dark,
      Brightness.light => SystemUiOverlayStyle.light
    };
  }

  Color getColor({
    Color dark = const Color(0xFF000000),
    Color light = const Color(0xFFFFFFFF),
  }) {
    return switch (this) { Brightness.dark => dark, Brightness.light => light };
  }
}

extension TextDirectionExtensions on TextDirection {
  TextDirection get inverted {
    return switch (this) {
      TextDirection.ltr => TextDirection.rtl,
      TextDirection.rtl => TextDirection.ltr
    };
  }
}

enum AsyncSnapshotState { errored, loading, done }

extension PostExtensions on Post {
  Post get root {
    final repeatOf = this.repeatOf;
    return repeatOf == null ? this : repeatOf.root;
  }
}

extension VectorExtensions<T> on Iterable<Iterable<T>> {
  List<T> concat() {
    final list = <T>[];
    for (final childList in this) {
      list.addAll(childList);
    }
    return list;
  }
}

extension HtmlNodeExtensions on Node {
  bool hasClass(String className) {
    return attributes["class"]?.split(" ").contains(className) == true;
  }
}

extension WidgetRefExtensions on WidgetRef {
  String getCurrentAccountHandle() {
    final accountKey = read(currentAccountProvider)!.key;
    return "@${accountKey.username}@${accountKey.host}";
  }

  Map<String, String> get accountRouterParams {
    final accountKey = read(currentAccountProvider)!.key;
    return accountKey.routerParams;
  }
}

extension ProviderContainerExtensions on ProviderContainer {
  Map<String, String> get accountRouterParams {
    final accountKey = read(currentAccountProvider)!.key;
    return accountKey.routerParams;
  }
}

extension AccountKeyExtensions on AccountKey {
  Map<String, String> get routerParams {
    return {"accountUsername": username, "accountHost": host};
  }
}

extension QueryExtension on Map<String, String> {
  String toQueryString() {
    if (isEmpty) return "";

    final pairs = <String>[];
    for (final kv in entries) {
      final key = Uri.encodeQueryComponent(kv.key);
      final value = Uri.encodeQueryComponent(kv.value);
      pairs.add("$key=$value");
    }
    return "?${pairs.join("&")}";
  }
}

extension ListExtensions<T> on List<T> {
  List<T> joinWithValue(T separator) {
    if (length <= 1) return this;

    return List<T>.generate(
      length * 2 - 1,
      (i) => i.isEven ? this[i ~/ 2] : separator,
    );
  }
}

extension NullableTextStyleExtensions on TextStyle? {
  /// Provides an empty [TextStyle] if null. For use with [TextStyle.copyWith].
  TextStyle get fallback => this ?? const TextStyle();
}

Locale parseLocale(String locale) {
  final split = locale.split("-");
  return switch (split.length) {
    1 => Locale(split[0]),
    2 => Locale(split[0], split[1]),
    3 => Locale.fromSubtags(
        languageCode: split[0],
        scriptCode: split[1],
        countryCode: split[2],
      ),
    _ => throw ArgumentError.value(locale, "locale", "Must be a valid locale"),
  };
}

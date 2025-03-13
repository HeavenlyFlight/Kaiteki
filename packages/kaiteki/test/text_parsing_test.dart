import "package:kaiteki/text/elements.dart";
import "package:kaiteki/text/parsers.dart";
import "package:kaiteki_core/model.dart";
import "package:test/test.dart";

void main() {
  test("parse link", () {
    const html = '<a href="https://craftplacer.moe/">look a cool site</a>';
    final expectedUri = Uri(
      scheme: "https",
      host: "craftplacer.moe",
      path: "/",
    );

    expect(
      const HtmlTextParser().parse(html).single,
      const TypeMatcher<LinkElement>()
          .having((e) => e.destination, "destination", equals(expectedUri))
          .having(
            (e) => e.children![0],
            "child",
            const TypeMatcher<TextElement>().having(
              (t) => t.text,
              "text",
              equals("look a cool site"),
            ),
          ),
    );
  });

  test("parse text with styles", () {
    const html = "<i>italic text</i><b>bold text</b>";
    final elements = const HtmlTextParser().parse(html);

    expect(
      elements.elementAt(0),
      const TypeMatcher<TextStyleElement>()
          .having((e) => e.style.italic, "italic", isTrue),
    );

    expect(
      elements.elementAt(1),
      const TypeMatcher<TextStyleElement>()
          .having((e) => e.style.bold, "bold", isTrue),
    );
  });

  group("parse mentions", () {
    final elements = const SocialTextParser().parse(
      "@Craftplacer Hey are you there? "
      "@Craftplacer@pl.craftplacer.moe maybe at your alt. "
      "@@ @*@* @ @",
    );

    test(
      "parse mention without host",
      () => expect(
        elements[0],
        const TypeMatcher<MentionElement>()
            .having((e) => e.reference.username, "username", "Craftplacer"),
      ),
    );

    test(
      "parse mention with host",
      () => expect(
        elements[2],
        const TypeMatcher<MentionElement>()
            .having((e) => e.reference.username, "username", "Craftplacer")
            .having((e) => e.reference.host, "instance", "pl.craftplacer.moe"),
      ),
    );
  });

  group("mixed parsing", () {
    test("easy", () {
      const input = "<b>@Craftplacer Hey are you there?</b>";
      final elements = const HtmlTextParser() //
          .parse(input)
          .parseWith(const SocialTextParser());

      expect(
        elements.elementAt(0),
        const TypeMatcher<TextStyleElement>()
            .having((e) => e.style.bold, "bold", isTrue)
            .having(
              (e) => e.children![0],
              "child",
              const TypeMatcher<MentionElement>().having(
                (m) => m.reference.username,
                "username",
                equals("Craftplacer"),
              ),
            ),
      );
    });

    test("hard", () {
      const input = "<b><i>@Craftplacer</i> Hey are you there? "
          "Can you visit "
          '<a href="https://craftplacer.moe/"> my website?</a></b>';

      final parseOne = const HtmlTextParser().parse(input);
      final parseTwo = parseOne.parseWith(const SocialTextParser());

      search(
        parseTwo.first,
        const TypeMatcher<MentionElement>().having(
          (m) => m.reference.username,
          "username",
          equals("Craftplacer"),
        ),
      );
    });
  });

  test("Mastodon mention & hashtag", () {
    const input =
        '<a href="https://floss.social/tags/Test" class="mention hashtag" rel="tag">#<span>Test</span></a>'
        " "
        '<span class="h-card"><a href="https://floss.social/@Kaiteki" class="u-url mention">@<span>Kaiteki</span></a></span>';

    final parsed = const MastodonHtmlTextParser().parse(input);

    expect(
      parsed,
      orderedEquals(const [
        HashtagElement("Test"),
        TextElement(" "),
        MentionElement(
          UserReference.url("https://floss.social/@Kaiteki"),
        ),
      ]),
    );
  });

  test("MFM scale", () {
    const input = r"$[x2 test]";

    final parsed = const MfmTextParser().parse(input);

    expect(
      parsed,
      orderedEquals([
        const TextStyleElement(
          TextElementStyle(scale: 2.0),
          [TextElement("test")],
        ),
      ]),
    );
  });

  test("non-empty element on html parse", () {
    const text =
        "follow our account for passionate rants about misskey and flutter";

    expect(
      const HtmlTextParser().parse("<p><span>$text</span></p>"),
      orderedEquals([const TextElement(text)]),
    );
  });
}

bool search(Element element, Matcher matcher, [bool recursive = false]) {
  if (matcher.matches(element, {})) {
    return true;
  } else if (element is WrapElement) {
    final children = element.children ?? const <Element>[];
    for (final child in children) {
      if (search(child, matcher, true)) return true;
    }
  }

  if (!recursive) {
    fail("Couldn't find anything that matches");
  }

  return false;
}

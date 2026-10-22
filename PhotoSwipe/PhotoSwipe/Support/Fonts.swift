import SwiftUI
import CoreText

// MARK: - Schibsted Grotesk (mgDesign UI face, OFL-1.1)
// Two static weights only, 400 and 600. Each file is a single weight, so pick
// it by PostScript name; `.weight()` on these would just synthesize.
// Don't use `.monospacedDigit()` with it: the font's tabular set also swaps
// in a digit-wide comma, period and percent, so "7,650" spreads apart.

enum TidyWeight { case regular, semibold }

enum AppFonts {
    /// The target generates its Info.plist, which has no build setting for
    /// UIAppFonts, so the bundled files are registered at launch instead.
    static func register() {
        for name in ["SchibstedGrotesk-Regular", "SchibstedGrotesk-SemiBold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing font \(name).ttf in the app bundle"); continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    /// Scales with Dynamic Type, like the text-style fonts it replaces.
    static func tidy(_ size: CGFloat, _ weight: TidyWeight = .regular,
                     relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(tidyName(weight), size: size, relativeTo: style)
    }

    /// Fixed size, like the `.system(size:)` fonts it replaces: stamps, big
    /// counts and badges whose layout doesn't stretch.
    static func tidyFixed(_ size: CGFloat, _ weight: TidyWeight = .regular) -> Font {
        .custom(tidyName(weight), fixedSize: size)
    }

    private static func tidyName(_ weight: TidyWeight) -> String {
        weight == .semibold ? "SchibstedGrotesk-SemiBold" : "SchibstedGrotesk-Regular"
    }
}

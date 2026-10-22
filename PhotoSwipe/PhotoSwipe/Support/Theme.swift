import SwiftUI

// MARK: - Palette
// mgDesign mg-core, dark mode (theme.css 0.1.0, OKLCH converted to sRGB).

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

enum Theme {
    // Surfaces: warm charcoal, not blue-black.
    static let bg0  = Color(hex: 0x0E0D0A)
    static let bg1  = Color(hex: 0x171613)
    static let card = Color(hex: 0x171613)
    static let cardPressed = Color(hex: 0x272623)
    static let stroke = Color(hex: 0x34332F)
    static let strokeStrong = Color(hex: 0x72726E)

    // Text. Quieter text is a quieter colour, never an in-between weight.
    static let textStrong = Color(hex: 0xF0EEE9)  // headings, counts
    static let text       = Color(hex: 0xDCDBD5)  // body
    static let textMuted  = Color(hex: 0xB9B7B2)  // secondary labels
    static let textDim    = Color(hex: 0x93928D)  // metadata

    // Swipe actions: base, then one step darker for the gradient end.
    static let keep      = Color(hex: 0x85B565)   // right, moss
    static let keep2     = Color(hex: 0x638F45)
    static let trash     = Color(hex: 0xF0555B)   // left
    static let trash2    = Color(hex: 0xCF4047)
    static let favorite  = Color(hex: 0xEBBC63)   // up, amber
    static let favorite2 = Color(hex: 0xD8953D)
    static let album     = Color(hex: 0x89A9C1)   // album button, slate
    static let album2    = Color(hex: 0x688BA4)
    static let later     = Color(hex: 0xB9B7B2)   // down: neutral on purpose

    // Text and icons ON a filled action colour. White fails contrast on
    // every one of these fills (1.8 to 3.4:1), so always use these instead.
    static let onKeep     = Color(hex: 0x0F1909)
    static let onTrash    = Color(hex: 0x250E0E)
    static let onFavorite = Color(hex: 0x1F1401)
    static let onAlbum    = Color(hex: 0x031826)

    static let cardCorner: CGFloat = 30
    static let swipeThreshold: CGFloat = 105

    static func gradient(_ a: Color, _ b: Color) -> LinearGradient {
        LinearGradient(colors: [a, b], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Motion tokens
// Golden curve feel translated to SwiftUI. High-freq = snappy; rare = expressive.

extension Animation {
    /// Card settle / return — snappy with a touch of life.
    static let cardSpring = Animation.spring(response: 0.34, dampingFraction: 0.78)
    /// Fling-off easing (exit). Fast accelerate.
    static let fling = Animation.easeIn(duration: 0.26)
    /// Press micro-interaction.
    static let press = Animation.spring(response: 0.22, dampingFraction: 0.6)
    /// Phase / view transitions — expressive (rare).
    static let phase = Animation.spring(response: 0.5, dampingFraction: 0.82)
}

// MARK: - Shared modifiers

extension View {
    func cardShadow() -> some View {
        shadow(color: .black.opacity(0.5), radius: 28, x: 0, y: 18)
    }
}

// MARK: - Pressable button style (scale + soft press)

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.9
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.press, value: configuration.isPressed)
    }
}

// MARK: - Aurora background
// Slow-drifting accent blobs over the dark base. Subtle, alive, never noticed.

struct AuroraBackground: View {
    @State private var drift = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(colors: [Theme.bg1, Theme.bg0],
                               startPoint: .top, endPoint: .bottom)

                blob(Theme.album, size: 460)
                    .position(x: w * (drift ? 0.20 : 0.30), y: h * (drift ? 0.10 : 0.04))
                blob(Theme.keep, size: 380)
                    .position(x: w * (drift ? 0.85 : 0.78), y: h * (drift ? 0.92 : 0.98))
                blob(Theme.favorite, size: 300)
                    .position(x: w * (drift ? 0.82 : 0.92), y: h * (drift ? 0.08 : 0.12))
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func blob(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [color.opacity(0.12), .clear],
                                 center: .center, startRadius: 0, endRadius: size / 2))
            .frame(width: size, height: size)
            .blur(radius: 50)
    }
}

// MARK: - Animated count (smooth numeric roll)

struct AnimatedCount: View {
    let value: Int
    var font: Font = .tidy(20, .semibold, relativeTo: .title3)
    var color: Color = Theme.textStrong

    var body: some View {
        Text("\(value)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(value)))
            .animation(.snappy(duration: 0.4), value: value)
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

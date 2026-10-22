import SwiftUI

@main
struct PhotoSwipeApp: App {
    init() { AppFonts.register() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .font(.tidy(16, relativeTo: .body))   // text with no font of its own
                .preferredColorScheme(.dark)
        }
    }
}

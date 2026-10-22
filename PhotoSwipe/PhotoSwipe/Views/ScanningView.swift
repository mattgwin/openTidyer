import SwiftUI

/// Duplicate-scan progress. A determinate ring driven by `vm.scanProgress`.
struct ScanningView: View {
    @ObservedObject var vm: SwipeDeckViewModel

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Theme.stroke, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: vm.scanProgress)
                    .stroke(Theme.gradient(Theme.album, Theme.keep),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy(duration: 0.25), value: vm.scanProgress)
                Text("\(Int(vm.scanProgress * 100))%")
                    .font(.tidyFixed(24, .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textStrong)
                    .contentTransition(.numericText())
            }
            .frame(width: 140, height: 140)

            VStack(spacing: 4) {
                Text("Scanning for duplicates")
                    .font(.tidy(20, .semibold, relativeTo: .title3))
                    .foregroundStyle(Theme.textStrong)
                Text("Comparing photos on-device")
                    .font(.tidy(14, relativeTo: .subheadline))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .padding(40)
    }
}

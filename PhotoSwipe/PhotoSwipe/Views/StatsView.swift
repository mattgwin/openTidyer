import SwiftUI

func byteString(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: max(0, bytes), countStyle: .file)
}

/// Full analytics sheet.
struct StatsView: View {
    @ObservedObject var vm: SwipeDeckViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    rows
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(Theme.bg0)
            .navigationTitle("Your impact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(Theme.album)
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    private var hero: some View {
        VStack(spacing: 6) {
            Image(systemName: "internaldrive.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.gradient(Theme.keep, Theme.album))
            Text(byteString(vm.stats.freedBytes))
                .font(.tidyFixed(48, .semibold))
                .tracking(-0.96)
                .foregroundStyle(Theme.textStrong)
            Text("freed across \(vm.stats.sessions) cleanup\(vm.stats.sessions == 1 ? "" : "s")")
                .font(.tidy(14, relativeTo: .subheadline))
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var rows: some View {
        VStack(spacing: 0) {
            row("trash.fill", Theme.trash, "Photos deleted", vm.stats.deletedCount)
            divider
            row("square.on.square.dashed", Theme.album, "Duplicates removed", vm.stats.duplicatesRemoved)
            divider
            row("checkmark.circle.fill", Theme.keep, "Cleanup sessions", vm.stats.sessions)
            divider
            resetRow
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.stroke))
    }

    private var divider: some View {
        Rectangle().fill(Theme.stroke).frame(height: 1).padding(.horizontal, 18)
    }

    private func row(_ icon: String, _ color: Color, _ label: String, _ value: Int) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(Circle().fill(color.opacity(0.14)))
            Text(label)
                .font(.tidy(16, relativeTo: .body))
                .foregroundStyle(Theme.text)
            Spacer()
            AnimatedCount(value: value, color: color)
        }
        .padding(.horizontal, 18).padding(.vertical, 15)
    }

    private var resetRow: some View {
        Button {
            if confirmReset { Haptics.warning(); vm.resetStats(); confirmReset = false }
            else { Haptics.tap(); confirmReset = true }
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text(confirmReset ? "Tap again to confirm reset" : "Reset analytics")
                Spacer()
            }
            .font(.tidy(14, relativeTo: .subheadline))
            .foregroundStyle(confirmReset ? Theme.trash : Theme.textDim)
            .padding(.horizontal, 18).padding(.vertical, 15)
        }
    }
}

import SwiftUI

/// Home screen: pick what to review. Premium tile grid + year chips.
struct SourcePickerView: View {
    @ObservedObject var vm: SwipeDeckViewModel
    @State private var showStats = false
    @State private var openList: DecidedList?
    @State private var confirmReset = false

    private let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                title

                if vm.pendingTrashCount > 0 { pendingTrashBanner }

                if vm.stats.deletedCount > 0 || vm.stats.freedBytes > 0 {
                    StatsHeroCard(stats: vm.stats) { showStats = true }
                }

                LazyVGrid(columns: cols, spacing: 14) {
                    tile(.all, subtitle: "\(vm.facets.total) photos")
                    tile(.duplicates, subtitle: "Scan & merge")
                    listTile(.kept, count: vm.keptAssets.count)
                    listTile(.trash, count: vm.pendingTrash.count)
                    tile(.screenshots, subtitle: "\(vm.facets.screenshots) shots")
                    tile(.largest, subtitle: "Free space fast")
                }

                if !vm.facets.years.isEmpty {
                    Text("BY YEAR")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(Theme.textDim)
                    yearChips
                }

                resetButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: 4) }
        .sheet(isPresented: $showStats) {
            StatsView(vm: vm)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $openList) { list in
            DecidedPhotosView(list: list, vm: vm)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("TIDYER")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(2.4)
                .foregroundStyle(Theme.textDim)
            Text("Tidy up")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textStrong)
        }
        .padding(.top, 4)
    }

    private func tile(_ source: PhotoSource, subtitle: String) -> some View {
        Button {
            Haptics.tap()
            vm.select(source)
        } label: {
            tileLabel(icon: source.icon, tint: source.tint, title: source.title, subtitle: subtitle)
        }
        .buttonStyle(PressableStyle(scale: 0.96))
    }

    /// Kept / To delete: opens the photo grid instead of starting a deck.
    private func listTile(_ list: DecidedList, count: Int) -> some View {
        Button {
            Haptics.tap()
            openList = list
        } label: {
            tileLabel(icon: list.icon, tint: list.tint, title: list.title,
                      subtitle: "\(count) photo\(count == 1 ? "" : "s")")
        }
        .buttonStyle(PressableStyle(scale: 0.96))
    }

    private func tileLabel(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Theme.gradient(tint, tint.opacity(0.6)))
                .frame(width: 50, height: 50)
                .background(Circle().fill(tint.opacity(0.14)))
            Spacer(minLength: 18)
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textStrong)
            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.gradient(tint.opacity(0.4), .clear), lineWidth: 1)
        )
    }

    private var yearChips: some View {
        let columns = [GridItem(.adaptive(minimum: 86), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(vm.facets.years, id: \.year) { y in
                Button {
                    Haptics.tap(); vm.select(.year(y.year))
                } label: {
                    VStack(spacing: 1) {
                        Text(String(y.year))
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.textStrong)
                        Text("\(y.count)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.stroke))
                }
                .buttonStyle(PressableStyle(scale: 0.94))
            }
        }
    }

    private var pendingTrashBanner: some View {
        Button {
            Haptics.tap(.rigid)
            Task { await vm.commitPendingTrash(returnToPicker: true) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.onTrash)
                    .frame(width: 42, height: 42)
                    .background(Theme.gradient(Theme.trash, Theme.trash2), in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(vm.pendingTrashCount) photos ready to delete")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.textStrong)
                    Text("From your last session — tap to delete")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textDim)
                }
                Spacer()
                if vm.isCommitting { ProgressView().tint(Theme.textStrong) }
                else { Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.textDim) }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.trash.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(PressableStyle(scale: 0.98))
        .disabled(vm.isCommitting)
    }

    private var resetButton: some View {
        // Two taps: a reset now also empties the Kept list.
        Button {
            if confirmReset { Haptics.warning(); vm.resetProgress(); confirmReset = false }
            else { Haptics.tap(.medium); confirmReset = true }
        } label: {
            Label(confirmReset ? "Tap again to reset (clears Kept)" : "Reset review progress",
                  systemImage: "arrow.counterclockwise")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(confirmReset ? Theme.trash : Theme.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(PressableStyle(scale: 0.97))
        .padding(.top, 4)
    }
}

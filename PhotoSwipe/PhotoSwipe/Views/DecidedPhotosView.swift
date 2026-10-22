import SwiftUI
import Photos

/// The two decision lists on the home screen. Kept = swiped right, favorited,
/// or filed to an album. To Delete = the pending-trash queue.
enum DecidedList: Identifiable {
    case kept
    case trash

    var id: Self { self }

    var title: String { self == .kept ? "Kept" : "To Delete" }
    var icon: String { self == .kept ? "heart.fill" : "trash.fill" }
    var tint: Color { self == .kept ? Theme.keep : Theme.trash }
    var tint2: Color { self == .kept ? Theme.keep2 : Theme.trash2 }
    var onTint: Color { self == .kept ? Theme.onKeep : Theme.onTrash }

    /// The change-of-mind action, which sends a photo to the other list.
    var moveLabel: String { self == .kept ? "Move to delete" : "Keep instead" }
    var moveIcon: String { self == .kept ? "trash" : "heart" }
}

/// Thumbnail grid of one decision list. Tap a photo to see it large and
/// change your mind. Deleting still only happens through the queue's
/// Delete button, the same commit the review screen uses.
struct DecidedPhotosView: View {
    let list: DecidedList
    @ObservedObject var vm: SwipeDeckViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let photos = list == .kept ? vm.keptAssets : vm.pendingTrash
        NavigationStack {
            Group {
                if photos.isEmpty { emptyState } else { grid(photos) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if list == .trash && !photos.isEmpty { deleteButton(photos.count) }
            }
            .background(Theme.bg0)
            .navigationTitle("\(list.title) · \(photos.count)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PHAsset.self) { asset in
                DecidedPhotoDetail(asset: asset, list: list, vm: vm)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(Theme.album)
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    private func grid(_ photos: [PHAsset]) -> some View {
        GeometryReader { geo in
            let spacing: CGFloat = 6
            let side = max(floor((geo.size.width - 32 - spacing * 2) / 3), 40)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(side), spacing: spacing), count: 3),
                          spacing: spacing) {
                    ForEach(photos, id: \.localIdentifier) { asset in
                        NavigationLink(value: asset) {
                            Thumbnail(asset: asset, side: side)
                        }
                        .buttonStyle(PressableStyle(scale: 0.95))
                        .contextMenu {
                            Button {
                                Haptics.soft(); vm.move(asset, outOf: list)
                            } label: {
                                Label(list.moveLabel, systemImage: list.moveIcon)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func deleteButton(_ count: Int) -> some View {
        Button {
            Haptics.tap(.rigid)
            Task { await vm.commitPendingTrash(returnToPicker: true) }
        } label: {
            HStack(spacing: 10) {
                if vm.isCommitting { ProgressView().tint(Theme.onTrash) }
                else { Image(systemName: "trash.fill") }
                Text("Delete \(count) photos")
                    .font(.tidy(16, .semibold, relativeTo: .headline))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(Theme.gradient(Theme.trash, Theme.trash2),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(Theme.onTrash)
        }
        .buttonStyle(PressableStyle(scale: 0.97))
        .disabled(vm.isCommitting)
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: list.icon)
                .font(.system(size: 44))
                .foregroundStyle(list.tint.opacity(0.6))
            Text(list == .kept ? "Nothing kept yet" : "Nothing to delete")
                .font(.tidyFixed(24, .semibold))
                .foregroundStyle(Theme.textStrong)
            Text(list == .kept
                 ? "Photos you swipe right show up here."
                 : "Photos you swipe left wait here until you delete them.")
                .font(.tidy(14, relativeTo: .subheadline))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textDim)
                .padding(.horizontal, 40)
        }
    }
}

/// One photo, large, with the button to send it to the other list.
private struct DecidedPhotoDetail: View {
    let asset: PHAsset
    let list: DecidedList
    @ObservedObject var vm: SwipeDeckViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    private let service = PhotoLibraryService()

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ProgressView().tint(Theme.textStrong)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
        .safeAreaInset(edge: .bottom, spacing: 0) { moveButton }
        .background(Theme.bg0)
        .task(id: asset.localIdentifier) {
            let screen = UIScreen.main.bounds.size
            let scale = UIScreen.main.scale
            image = await service.requestImage(
                for: asset,
                targetSize: CGSize(width: screen.width * scale, height: screen.height * scale),
                contentMode: .aspectFit)
        }
    }

    private var moveButton: some View {
        let target: DecidedList = list == .kept ? .trash : .kept
        return Button {
            Haptics.soft()
            vm.move(asset, outOf: list)
            dismiss()
        } label: {
            Label(list.moveLabel, systemImage: target.icon)
                .font(.tidy(16, .semibold, relativeTo: .headline))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Theme.gradient(target.tint, target.tint2),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(target.onTint)
        }
        .buttonStyle(PressableStyle(scale: 0.97))
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
    }
}

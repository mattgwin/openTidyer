import SwiftUI
import Photos
import PhotosUI

/// Full-screen look at the photo behind a card: pinch or double-tap to zoom,
/// and Live Photos play once (touch and hold to replay). Opened by a long
/// press on the card. iOS has no public way to open one specific asset in
/// the Photos app, so this is shown in-app instead.
struct OriginalPhotoView: View {
    let asset: PHAsset
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var image: UIImage?
    @State private var livePhoto: PHLivePhoto?
    @State private var loading = true
    private let service = PhotoLibraryService()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if image != nil || livePhoto != nil {
                ZoomableAssetView(image: image, livePhoto: livePhoto)
                    .ignoresSafeArea()
            } else if !loading {
                Text("Couldn't load this photo")
                    .font(.tidy(16, relativeTo: .body))
                    .foregroundStyle(Theme.textDim)
            }
            if loading && image == nil {
                ProgressView().tint(Theme.textDim)
            }
        }
        .overlay(alignment: .top) { topBar }
        .statusBarHidden()
        .task(id: asset.localIdentifier) { await load() }
    }

    private var topBar: some View {
        HStack {
            circleButton("xmark") { dismiss() }
            Spacer()
            if loading && image != nil {
                ProgressView().controlSize(.small).tint(Theme.textDim)
            }
            Spacer()
            // Undocumented URL scheme: opens the Photos app where it last
            // was, not at this photo. Nothing happens if it ever stops working.
            circleButton("arrow.up.forward.app") {
                if let url = URL(string: "photos-redirect://") { openURL(url) }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func circleButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap(); action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textStrong)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Theme.stroke))
        }
        .buttonStyle(PressableStyle())
    }

    /// Screen-sized first so something shows at once, then the original.
    private func load() async {
        let screen = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        image = await service.requestImage(
            for: asset,
            targetSize: CGSize(width: screen.width * scale, height: screen.height * scale),
            contentMode: .aspectFit)

        let full = originalSize
        if asset.mediaSubtypes.contains(.photoLive),
           let live = await service.requestLivePhoto(for: asset, targetSize: full) {
            livePhoto = live
        } else if let original = await service.requestImage(for: asset, targetSize: full,
                                                             contentMode: .aspectFit) {
            image = original
        }
        loading = false
    }

    /// The asset's own pixel size, capped at 4096 on the long edge: 3x zoom
    /// on any iPhone screen, without decoding a 48 MP photo (~190 MB) at once.
    private var originalSize: CGSize {
        let w = CGFloat(asset.pixelWidth), h = CGFloat(asset.pixelHeight)
        let s = min(1, 4096 / max(w, h, 1))
        return CGSize(width: w * s, height: h * s)
    }
}

/// UIScrollView zoom (pinch, double-tap) around either a still image or a
/// Live Photo. SwiftUI has no built-in zoomable image view.
private struct ZoomableAssetView: UIViewRepresentable {
    let image: UIImage?
    let livePhoto: PHLivePhoto?

    func makeUIView(context: Context) -> ZoomScrollView { ZoomScrollView(frame: .zero) }

    func updateUIView(_ view: ZoomScrollView, context: Context) {
        view.imageView.image = image
        view.imageView.isHidden = livePhoto != nil
        view.liveView.isHidden = livePhoto == nil
        if view.liveView.livePhoto !== livePhoto {
            view.liveView.livePhoto = livePhoto
            if livePhoto != nil { view.liveView.startPlayback(with: .full) }
        }
    }
}

private final class ZoomScrollView: UIScrollView, UIScrollViewDelegate {
    let imageView = UIImageView()
    let liveView = PHLivePhotoView()
    private let container = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 4
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        backgroundColor = .clear

        // Both views fill the container and aspect-fit; zooming scales it.
        for view in [imageView, liveView] as [UIView] {
            view.contentMode = .scaleAspectFit
            view.frame = container.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.addSubview(view)
        }
        addSubview(container)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(toggleZoom(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Track the screen size (rotation, first layout) only when not zoomed.
        if zoomScale == minimumZoomScale, container.frame.size != bounds.size {
            container.frame = CGRect(origin: .zero, size: bounds.size)
            contentSize = bounds.size
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { container }

    @objc private func toggleZoom(_ tap: UITapGestureRecognizer) {
        if zoomScale > minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let point = tap.location(in: container)
            let size = CGSize(width: bounds.width / 2.5, height: bounds.height / 2.5)
            zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                            width: size.width, height: size.height),
                 animated: true)
        }
    }
}

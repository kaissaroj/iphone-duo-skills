import SwiftUI

// MARK: - Now Playing
//
// Fold-aware Now Playing screen for a podcast app.
//
// Layout strategy (no UIKit, no hardcoded hinge geometry):
//
//   * Wide / unfolded (regular horizontal size class, enough width):
//       Player and Transcript sit side by side, one per "pane". Each pane is
//       laid out from the *outer* edge inwards and is padded away from the
//       centre of the container so nothing important straddles the fold.
//       The seam between the two panes is deliberately left empty.
//
//   * Narrow / closed (compact horizontal size class, or the window is narrow
//       enough that two panes don't fit):
//       The HStack collapses into a single-column layout. The transcript is
//       shown as a sheet-like inspector below the player (or as a full
//       sheet when the height is also constrained) instead of squeezing both
//       views into one narrow column.
//
//   * The `isTranscriptVisible` toggle still works in every configuration.
//
// The decision is driven purely by size classes and the proposed container
// size, so the same code behaves correctly on iPhone, iPhone Duo (open /
// half-open / closed) and iPad without branching on device model.

struct NowPlayingView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var isTranscriptVisible = true
    @State private var showsTranscriptSheet = false

    /// Below this width we never attempt a two-pane layout, regardless of
    /// size class (guards against half-open / narrow window states).
    private let twoPaneMinimumWidth: CGFloat = 640

    /// Gutter kept clear on either side of the centre line. On a folding
    /// device this is the area that sits over the hinge.
    private let centreGutter: CGFloat = 24

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let size = proxy.size
                let layout = resolvedLayout(for: size)

                Group {
                    switch layout {
                    case .twoPane:
                        twoPaneLayout(width: size.width)
                    case .stacked:
                        stackedLayout
                    case .single:
                        singlePaneLayout
                    }
                }
                .frame(width: size.width, height: size.height)
                .animation(.snappy, value: layout)
                .animation(.snappy, value: isTranscriptVisible)
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $isTranscriptVisible) {
                        Label("Transcript", systemImage: "text.quote")
                    }
                    .toggleStyle(.button)
                    .accessibilityLabel("Show transcript")
                }
            }
            .sheet(isPresented: $showsTranscriptSheet) {
                NavigationStack {
                    TranscriptView()
                        .navigationTitle("Transcript")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showsTranscriptSheet = false }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: Layout resolution

    private enum Layout: Equatable {
        /// Player on the left pane, transcript on the right pane.
        case twoPane
        /// Player on top, transcript underneath (portrait, narrow, tall).
        case stacked
        /// Player only; transcript accessible via a sheet.
        case single
    }

    private func resolvedLayout(for size: CGSize) -> Layout {
        guard isTranscriptVisible else { return .single }

        let isWideEnough = size.width >= twoPaneMinimumWidth
        let isRegularWidth = horizontalSizeClass == .regular

        if isRegularWidth && isWideEnough {
            return .twoPane
        }

        // Compact width (closed device / narrow window). Only stack when the
        // view is tall enough to give both halves meaningful space.
        if size.height >= 700 && verticalSizeClass == .regular {
            return .stacked
        }

        return .single
    }

    // MARK: Two pane (unfolded)

    @ViewBuilder
    private func twoPaneLayout(width: CGFloat) -> some View {
        // Each pane gets exactly half the width; the centre gutter is carved
        // out of each pane's inner edge so content never crosses the middle.
        HStack(spacing: 0) {
            PlayerView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.trailing, centreGutter / 2)
                .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 0)

            TranscriptView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, centreGutter / 2)
                .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 0)
        }
        .frame(width: width)
    }

    // MARK: Stacked (closed, tall)

    private var stackedLayout: some View {
        VStack(spacing: 0) {
            PlayerView()
                .frame(maxWidth: .infinity)
                .layoutPriority(1)

            Divider()

            TranscriptView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Single (closed, short, or transcript hidden)

    private var singlePaneLayout: some View {
        PlayerView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                if isTranscriptVisible {
                    Button {
                        showsTranscriptSheet = true
                    } label: {
                        Label("Show Transcript", systemImage: "text.quote")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    .background(.bar)
                }
            }
    }
}

#Preview("Now Playing") {
    NowPlayingView()
}

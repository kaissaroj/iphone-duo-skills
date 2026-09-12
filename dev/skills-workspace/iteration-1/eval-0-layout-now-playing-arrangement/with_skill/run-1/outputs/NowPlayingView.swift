import SwiftUI

/// Now Playing screen for the podcast app, adapted for iPhone Duo (iOS 27.1).
///
/// Layout strategy (see NOTES.md):
/// - Regular width (inner display, open): `ArrangementView` in `.split` style holds
///   `PlayerView` (primary) and `TranscriptView` (secondary). The system positions the
///   two panes from size class + aspect ratio and keeps each pane inside its own
///   region when the device is partially folded, so nothing straddles the hinge.
/// - Compact width (outer display, closed; or a narrow Split View multitasking slot):
///   only `PlayerView` is shown, and the transcript is presented as a sheet on demand.
///
/// No orientation checks, no `UIScreen.main`, no fixed widths — the layout is driven
/// purely by the size-class environment and the arrangement container.
struct NowPlayingView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Whether the transcript pane is visible alongside the player (regular width).
    @State private var isTranscriptVisible = true

    /// Whether the transcript sheet is presented (compact width).
    @State private var isTranscriptSheetPresented = false

    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        // Navigation stays OUTSIDE the arrangement, per Apple's guidance.
        NavigationStack {
            Group {
                if isCompact {
                    compactContent
                } else {
                    regularContent
                }
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    transcriptToggle
                }
            }
            .sheet(isPresented: $isTranscriptSheetPresented) {
                // Sheets avoid the fold automatically; they are also the natural
                // "collapsed" form of the transcript on the outer display.
                NavigationStack {
                    TranscriptView()
                        .navigationTitle("Transcript")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { isTranscriptSheetPresented = false }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }
        }
        // Leaving the compact size class (device opened) while the sheet is up:
        // dismiss it so the transcript reappears as the secondary pane instead.
        .onChange(of: isCompact) { _, nowCompact in
            if !nowCompact { isTranscriptSheetPresented = false }
        }
    }

    // MARK: - Regular width (inner display)

    @ViewBuilder
    private var regularContent: some View {
        if isTranscriptVisible {
            ArrangementView {
                PlayerView()          // primary: never hidden
            } secondary: {
                TranscriptView()      // secondary: main/detail, must not be obscured -> .split
            }
            // Default `.split`: horizontal when wider than tall (open flat, landscape),
            // vertical when taller than wide (open, portrait). Both axes are allowed so
            // the transcript is never dropped by an axis restriction.
            .arrangementViewStyle(.split)
        } else {
            // Transcript collapsed: the player gets the whole area. ArrangementView's
            // split keeps the primary constrained to one region when folded; a lone
            // PlayerView is still positioned inside the safe area and its own
            // scrolling/centered content should avoid the fold via PlayerView's
            // system components. If PlayerView has custom centered controls, see
            // NOTES.md for the reserved-region displacement hook.
            PlayerView()
        }
    }

    // MARK: - Compact width (outer display / narrow multitasking slot)

    private var compactContent: some View {
        PlayerView()
    }

    // MARK: - Toolbar

    private var transcriptToggle: some View {
        Button {
            if isCompact {
                isTranscriptSheetPresented.toggle()
            } else {
                withAnimation { isTranscriptVisible.toggle() }
            }
        } label: {
            let showing = isCompact ? isTranscriptSheetPresented : isTranscriptVisible
            Label(showing ? "Hide Transcript" : "Show Transcript",
                  systemImage: showing ? "text.quote" : "text.quote")
                .symbolVariant(showing ? .fill : .none)
        }
        .accessibilityLabel(
            (isCompact ? isTranscriptSheetPresented : isTranscriptVisible)
                ? "Hide Transcript" : "Show Transcript"
        )
    }
}

#Preview("Now Playing") {
    NowPlayingView()
}

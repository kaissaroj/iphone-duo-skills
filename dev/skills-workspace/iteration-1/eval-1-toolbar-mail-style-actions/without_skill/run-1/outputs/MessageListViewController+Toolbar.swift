//
//  MessageListViewController+Toolbar.swift
//
//  Toolbar / navigation-bar action configuration for the message list screen.
//  Targets iOS 27.1. Designed to read correctly both in the classic horizontal
//  bars and in the narrow vertical bars used on iPhone Duo, by:
//    * using SF Symbols (no long text) for every item so they stack cleanly,
//    * exposing the inbox count as a compact badge-style pill rather than an
//      "Inbox (12)" text button,
//    * collapsing secondary actions into a single "More" UIMenu, and
//    * re-laying items out whenever the size class / layout direction changes.
//

import UIKit

// MARK: - Actions the host controller must provide

/// The host `MessageListViewController` is expected to implement these.
/// They are declared as a protocol so this extension compiles stand-alone and
/// the real controller can satisfy them however it likes.
protocol MessageListToolbarActions: AnyObject {
    var unreadCount: Int { get }
    var isFilterActive: Bool { get }
    var isSelecting: Bool { get }

    func compose()
    func toggleFilter()
    func setSelecting(_ selecting: Bool)
    func archiveSelectionOrAll()
    func markAllAsRead()
    func showSettings()
    func showInbox()
}

// MARK: - Toolbar configuration

extension MessageListViewController {

    // Accessibility identifiers so UI tests / QA tooling can find the items.
    enum ToolbarID {
        static let compose  = "messageList.compose"
        static let filter   = "messageList.filter"
        static let select   = "messageList.select"
        static let inbox    = "messageList.inboxCount"
        static let more     = "messageList.more"
    }

    /// Call once from `viewDidLoad()`.
    func configureToolbarItems() {
        buildBarButtonItems()
        applyToolbarLayout()

        // Re-run layout when the bars flip between horizontal and vertical
        // (iPhone Duo) or when the size class changes.
        registerForTraitChanges(
            [UITraitHorizontalSizeClass.self,
             UITraitVerticalSizeClass.self,
             UITraitLayoutDirection.self]
        ) { (self: Self, _: UITraitCollection) in
            self.applyToolbarLayout()
        }
    }

    /// Call whenever `unreadCount`, `isFilterActive`, or `isSelecting` changes.
    func refreshToolbarState() {
        updateInboxCount()
        updateFilterState()
        updateSelectState()
    }

    // MARK: Item construction

    private func buildBarButtonItems() {
        // Compose — primary action. `.compose` system item gives the platform
        // glyph, voice-over label, and Duo-aware sizing for free.
        let compose = UIBarButtonItem(
            systemItem: .compose,
            primaryAction: UIAction { [weak self] _ in self?.compose() }
        )
        compose.accessibilityIdentifier = ToolbarID.compose
        compose.accessibilityLabel = String(localized: "Compose")
        compose.style = .prominent          // iOS 26+: tinted, elevated glyph
        toolbarStore.compose = compose

        // Filter — toggles between outline / filled symbol.
        let filter = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            primaryAction: UIAction { [weak self] _ in self?.toggleFilter() }
        )
        filter.accessibilityIdentifier = ToolbarID.filter
        filter.accessibilityLabel = String(localized: "Filter")
        toolbarStore.filter = filter

        // Select / Done — same item, retitled when editing.
        let select = UIBarButtonItem(
            image: UIImage(systemName: "checkmark.circle"),
            primaryAction: UIAction { [weak self] _ in
                guard let self else { return }
                self.setSelecting(!self.isSelecting)
            }
        )
        select.accessibilityIdentifier = ToolbarID.select
        select.accessibilityLabel = String(localized: "Select")
        toolbarStore.select = select

        // Inbox count — a compact pill. On vertical bars a wide text button
        // like "Inbox (12)" would truncate, so we show a tray glyph with a
        // numeric badge and expose the full string to VoiceOver instead.
        let inbox = UIBarButtonItem(
            image: inboxImage(count: unreadCount),
            primaryAction: UIAction { [weak self] _ in self?.showInbox() }
        )
        inbox.accessibilityIdentifier = ToolbarID.inbox
        toolbarStore.inbox = inbox

        // More — deferred menu so it always reflects current state when opened.
        let more = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            menu: UIMenu(children: [
                UIDeferredMenuElement.uncached { [weak self] completion in
                    completion(self?.makeMoreMenuElements() ?? [])
                }
            ])
        )
        more.accessibilityIdentifier = ToolbarID.more
        more.accessibilityLabel = String(localized: "More")
        toolbarStore.more = more

        refreshToolbarState()
    }

    private func makeMoreMenuElements() -> [UIMenuElement] {
        let archiveTitle = isSelecting
            ? String(localized: "Archive Selected")
            : String(localized: "Archive All")

        let archive = UIAction(
            title: archiveTitle,
            image: UIImage(systemName: "archivebox")
        ) { [weak self] _ in self?.archiveSelectionOrAll() }

        let markRead = UIAction(
            title: String(localized: "Mark All as Read"),
            image: UIImage(systemName: "envelope.open"),
            attributes: unreadCount == 0 ? [.disabled] : []
        ) { [weak self] _ in self?.markAllAsRead() }

        let settings = UIAction(
            title: String(localized: "Settings"),
            image: UIImage(systemName: "gear")
        ) { [weak self] _ in self?.showSettings() }

        // Group message actions separately from Settings.
        return [
            UIMenu(options: .displayInline, children: [archive, markRead]),
            UIMenu(options: .displayInline, children: [settings])
        ]
    }

    // MARK: Layout

    /// Distributes the items between the navigation bar and the bottom bar
    /// depending on the current traits.
    ///
    /// Regular / horizontal bars:
    ///   nav bar trailing: [Select]   bottom bar: [Filter] [Inbox] — — [More] [Compose]
    ///
    /// Compact / vertical bars (iPhone Duo side rail):
    ///   The bottom toolbar becomes a vertical rail. Order top→bottom is
    ///   importance-based, with Compose pinned at the reachable end and no
    ///   flexible spacers that would push items to the far corners.
    private func applyToolbarLayout() {
        guard let compose = toolbarStore.compose,
              let filter  = toolbarStore.filter,
              let select  = toolbarStore.select,
              let inbox   = toolbarStore.inbox,
              let more    = toolbarStore.more else { return }

        let usesVerticalBars = traitCollection.usesVerticalBars

        // Select / Done lives in the nav bar in both layouts; it's the only
        // item that changes semantics while on screen.
        navigationItem.rightBarButtonItem = select

        // Never let the system collapse Compose into an overflow menu.
        navigationItem.pinnedTrailingGroup = nil

        if usesVerticalBars {
            // Vertical rail: keep items tight, no flexible spaces.
            let gap = UIBarButtonItem.fixedSpace(12)
            toolbarItems = [compose, gap, filter, gap, inbox, gap, more]
        } else {
            toolbarItems = [
                filter,
                .fixedSpace(16),
                inbox,
                .flexibleSpace(),
                more,
                .fixedSpace(16),
                compose
            ]
        }

        navigationController?.setToolbarHidden(false, animated: false)
    }

    // MARK: State updates

    private func updateInboxCount() {
        guard let inbox = toolbarStore.inbox else { return }
        inbox.image = inboxImage(count: unreadCount)
        inbox.accessibilityLabel = String(
            localized: "Inbox, \(unreadCount) unread"
        )
        inbox.accessibilityValue = "\(unreadCount)"
    }

    private func updateFilterState() {
        guard let filter = toolbarStore.filter else { return }
        filter.image = UIImage(
            systemName: isFilterActive
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle"
        )
        filter.accessibilityValue = isFilterActive
            ? String(localized: "On")
            : String(localized: "Off")
    }

    private func updateSelectState() {
        guard let select = toolbarStore.select else { return }
        if isSelecting {
            select.image = nil
            select.title = String(localized: "Done")
            select.style = .done
            select.accessibilityLabel = String(localized: "Done")
        } else {
            select.title = nil
            select.image = UIImage(systemName: "checkmark.circle")
            select.style = .plain
            select.accessibilityLabel = String(localized: "Select")
        }
        // Compose is not meaningful while selecting.
        toolbarStore.compose?.isEnabled = !isSelecting
    }

    // MARK: Helpers

    /// A tray glyph with a numeric badge, rendered as a single symbol image so
    /// it behaves like any other bar item on a vertical rail.
    private func inboxImage(count: Int) -> UIImage? {
        let base = UIImage(systemName: "tray")
        guard count > 0 else { return base }

        let text = count > 99 ? "99+" : "\(count)"
        let config = UIImage.SymbolConfiguration(textStyle: .body)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 34, height: 28))
        return renderer.image { ctx in
            base?.withConfiguration(config)
                .withTintColor(.label, renderingMode: .alwaysOriginal)
                .draw(in: CGRect(x: 0, y: 4, width: 24, height: 22))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .caption2).withSize(9),
                .foregroundColor: UIColor.white
            ]
            let textSize = (text as NSString).size(withAttributes: attrs)
            let pill = CGRect(
                x: 34 - max(14, textSize.width + 6),
                y: 0,
                width: max(14, textSize.width + 6),
                height: 14
            )
            UIColor.systemRed.setFill()
            UIBezierPath(roundedRect: pill, cornerRadius: 7).fill()
            (text as NSString).draw(
                at: CGPoint(
                    x: pill.midX - textSize.width / 2,
                    y: pill.midY - textSize.height / 2
                ),
                withAttributes: attrs
            )
        }.withRenderingMode(.alwaysOriginal)
    }
}

// MARK: - Item storage

/// Holds strong references to the items so we can mutate them after creation.
final class MessageListToolbarStore {
    var compose: UIBarButtonItem?
    var filter:  UIBarButtonItem?
    var select:  UIBarButtonItem?
    var inbox:   UIBarButtonItem?
    var more:    UIBarButtonItem?
}

private var toolbarStoreKey: UInt8 = 0

extension MessageListViewController {
    var toolbarStore: MessageListToolbarStore {
        if let existing = objc_getAssociatedObject(self, &toolbarStoreKey) as? MessageListToolbarStore {
            return existing
        }
        let store = MessageListToolbarStore()
        objc_setAssociatedObject(self, &toolbarStoreKey, store, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return store
    }
}

// MARK: - Trait helpers

private extension UITraitCollection {
    /// True when the system lays the nav/tool bars out as vertical rails
    /// (iPhone Duo in its side-by-side configuration). We approximate this by
    /// "compact width, regular height with a wide-aspect window"; adjust if a
    /// dedicated trait is available in your SDK.
    var usesVerticalBars: Bool {
        horizontalSizeClass == .compact && verticalSizeClass == .regular
            && preferredContentSizeCategory.isAccessibilityCategory == false
            && UIDevice.current.userInterfaceIdiom == .phone
            && (UIScreen.main.bounds.width > UIScreen.main.bounds.height)
    }
}

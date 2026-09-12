//
//  MessageListViewController+Toolbar.swift
//
//  Toolbar / navigation-bar configuration for the message list.
//  Targets the iOS 27.1 SDK so the system can relocate these items onto
//  iPhone Duo's vertical bar (outer display in every orientation, inner
//  display in landscape). Nothing here builds its own UIToolbar or
//  UINavigationBar: all items are set on `navigationItem` / `toolbarItems`
//  and owned by the enclosing UINavigationController + UITabBarController,
//  which is the only way they are considered for the vertical bar.
//
//  Contract with the main class (declared in MessageListViewController.swift):
//
//      var isSelecting: Bool            // multi-select mode on/off
//      var inboxUnreadCount: Int        // drives the Inbox badge
//      func presentCompose()
//      func presentFilterOptions()
//      func showInbox()
//      func setSelecting(_ selecting: Bool, animated: Bool)
//      func archiveAllMessages()
//      func markAllMessagesRead()
//      func presentSettings()
//

import UIKit

extension MessageListViewController {

    // MARK: - Item identity

    /// Tags used to look items up again after they have been handed to the
    /// system (an extension cannot add stored properties).
    private enum ToolbarTag: Int {
        case compose = 1
        case filter
        case inbox
        case selectOrDone
    }

    // MARK: - Setup

    /// Call once from `viewDidLoad()`.
    func configureToolbarItems() {
        navigationController?.setToolbarHidden(false, animated: false)

        // ---- Top bar (navigation item) --------------------------------------
        //
        // Back is added by UINavigationController and always sits at the top
        // of the vertical strip. The Select/Done toggle is the screen's
        // prominent action, so it lives in `pinnedTrailingGroup`, directly
        // under Back in the strip. It is text-only and swaps its label, so it
        // is forced `.horizontalOnly`: symbol⇄text items must not change axis
        // between poses, and text-only items stay horizontal anyway.
        navigationItem.pinnedTrailingGroup = UIBarButtonItemGroup(
            barButtonItems: [makeSelectOrDoneItem()],
            representativeItem: nil
        )

        // ---- Bottom toolbar (owned by UINavigationController) ---------------
        //
        // Mail-style order: Filter (leading), Inbox status (centre),
        // Compose (trailing). In a vertical bar the flexible spaces collapse
        // to zero size and the system stacks the three items bottom-aligned;
        // in a horizontal bar they spread as usual. No manual spacing beyond
        // that. Every item has BOTH a symbol and a title, so each one is
        // eligible for the vertical bar and has a label for the overflow menu.
        toolbarItems = [
            makeFilterItem(),
            .flexibleSpace(),
            makeInboxItem(),
            .flexibleSpace(),
            makeComposeItem(),
        ]

        // ---- One overflow menu ------------------------------------------------
        //
        // Instead of our own ellipsis "More" button, the secondary actions are
        // folded into the system overflow menu. The ellipsis is reserved for the
        // system on iPhone; a second "more" menu would compete with it, and
        // anything the bar can't fit (Filter, Inbox) lands in the same place.
        navigationItem.additionalOverflowItems = UIDeferredMenuElement { [weak self] provider in
            provider(self?.persistentOverflowItems() ?? [])
        }

        // Default compression (toolbar collapses before the tab bar) is kept:
        // this is a navigation-focused screen inside a UITabBarController and
        // the mailbox tabs should stay reachable. Compose survives compression
        // through its visibility priority instead. If the tab bar is ever the
        // less important of the two here, flip it with:
        //     navigationItem.verticalBarCompressionBehavior = .prefersBarItems

        updateInboxBadge()
        updateSelectOrDoneItem(animated: false)
    }

    // MARK: - Item factories

    private func makeComposeItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(
            title: String(localized: "Compose"),
            image: UIImage(systemName: "square.and.pencil"),
            target: self,
            action: #selector(composeTapped)
        )
        item.tag = ToolbarTag.compose.rawValue
        // Most important action on the screen: overflows last. Items overflow
        // bottom→top by default and Compose is the bottom-most item, so the
        // priority is what keeps it on the bar when the outer display runs
        // out of height (keyboard up, landscape, PiP pinned at the top).
        item.visibilityPriority = UIBarButtonItemVisibilityPriority(higherThan: .high)
        return item
    }

    private func makeFilterItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(
            title: String(localized: "Filter"),
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            target: self,
            action: #selector(filterTapped)
        )
        item.tag = ToolbarTag.filter.rawValue
        // First to be folded into the overflow menu; its title is what shows there.
        item.visibilityPriority = .low
        return item
    }

    private func makeInboxItem() -> UIBarButtonItem {
        // Previously a text button "Inbox (12)". Text-only items are pinned to
        // the horizontal bar, and the number only reinforces the symbol, so it
        // becomes a symbol with a count badge — which also conveys status at a
        // glance and therefore stays visible longer than Filter.
        let item = UIBarButtonItem(
            title: String(localized: "Inbox"),
            image: UIImage(systemName: "tray"),
            target: self,
            action: #selector(inboxTapped)
        )
        item.tag = ToolbarTag.inbox.rawValue
        item.visibilityPriority = .high
        return item
    }

    private func makeSelectOrDoneItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(
            title: String(localized: "Select"),
            style: .plain,
            target: self,
            action: #selector(selectOrDoneTapped)
        )
        item.tag = ToolbarTag.selectOrDone.rawValue
        // Custom Select ⇄ Done toggle: keep it on the horizontal axis in every
        // pose so the pair never straddles two bars.
        item.axisBehavior = .horizontalOnly
        // Prominent action: must not disappear when the bar compresses.
        item.visibilityPriority = .high
        return item
    }

    // MARK: - Overflow menu contents ("More")

    /// The actions that used to live under a custom "More" ellipsis button.
    private func persistentOverflowItems() -> [UIMenuElement] {
        [
            UIAction(
                title: String(localized: "Archive All"),
                image: UIImage(systemName: "archivebox")
            ) { [weak self] _ in self?.archiveAllMessages() },

            UIAction(
                title: String(localized: "Mark All as Read"),
                image: UIImage(systemName: "envelope.open")
            ) { [weak self] _ in self?.markAllMessagesRead() },

            UIMenu(options: .displayInline, children: [
                UIAction(
                    title: String(localized: "Settings"),
                    image: UIImage(systemName: "gear")
                ) { [weak self] _ in self?.presentSettings() },
            ]),
        ]
    }

    // MARK: - State updates

    /// Call whenever `inboxUnreadCount` changes.
    func updateInboxBadge() {
        guard let item = toolbarItem(.inbox) else { return }
        item.badge = inboxUnreadCount > 0 ? .count(inboxUnreadCount) : nil
        item.accessibilityValue = inboxUnreadCount > 0
            ? String(localized: "\(inboxUnreadCount) unread")
            : nil
    }

    /// Call whenever `isSelecting` changes.
    func updateSelectOrDoneItem(animated: Bool) {
        guard let item = navigationItem.pinnedTrailingGroup?.barButtonItems
            .first(where: { $0.tag == ToolbarTag.selectOrDone.rawValue }) else { return }

        item.title = isSelecting ? String(localized: "Done") : String(localized: "Select")
        item.style = isSelecting ? .done : .plain

        // While selecting, Compose and Filter don't apply to the selection;
        // hide them rather than letting them compete for the strip.
        toolbarItem(.compose)?.isHidden = isSelecting
        toolbarItem(.filter)?.isHidden = isSelecting
    }

    private func toolbarItem(_ tag: ToolbarTag) -> UIBarButtonItem? {
        toolbarItems?.first { $0.tag == tag.rawValue }
    }

    // MARK: - Actions

    @objc private func composeTapped() {
        presentCompose()
    }

    @objc private func filterTapped() {
        presentFilterOptions()
    }

    @objc private func inboxTapped() {
        showInbox()
    }

    @objc private func selectOrDoneTapped() {
        setSelecting(!isSelecting, animated: true)
        updateSelectOrDoneItem(animated: true)
    }
}

//
//  CollectionViewItems.swift
//  PraxPress
//
//  Created by Elmer Cat on 3/14/26.
//

import SwiftUI
import AppKit

enum CollectionElementKind {
    case thumbnail(item: PDFPageItemModel)
    case page(item: PDFPageItemModel)
    case header(item: PDFPageSectionModel)
    case footer(item: PDFPageSectionModel)
    case background(indexPath: IndexPath)
    case none
    
}

struct CollectionElementHostView: View {
    let kind: CollectionElementKind
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    var body: some View {
        switch kind {
        case let .thumbnail(item):
            PageItemView( pdfPageItem: item, isSelected: isSelected, highlightState: highlightState )
        case let .page(item):
            PageEditView(pdfPageItem: item, isSelected: isSelected, highlightState: highlightState )
        case let .header(item):
            SectionHeaderView(pdfPageSection: item, isSelected: isSelected, highlightState: highlightState )
        case let .footer(item):
            SectionFooterView(pdfPageSection: item, isSelected: isSelected, highlightState: highlightState )
        case let .background(indexPath):
            SectionBackgroundView(indexPath: indexPath, isSelected: isSelected, highlightState: highlightState )
        case .none:
            EmptyView()
        }
    }
}
protocol CollectionElementHosting: AnyObject {
    var containerView: NSView { get }
    var isSelected: Bool { get set }
    var highlightState: NSCollectionViewItem.HighlightState { get set }
    var kind: CollectionElementKind? { get set }
    var hostingView: NSHostingView<CollectionElementHostView>? { get set }
    func updateRootView()
}

extension CollectionElementHosting {
    func attachIfNeeded() {
        guard hostingView == nil else { return }
        let hosting = NSHostingView(rootView: buildRootView())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: containerView.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        hostingView = hosting
    }

    func buildRootView() -> CollectionElementHostView {
        CollectionElementHostView(
            kind: kind ?? .none,
            isSelected: isSelected,
            highlightState: highlightState
        )
    }

    func updateRootView() {
        attachIfNeeded()
        hostingView?.rootView = buildRootView()
    }
}

final class CollectionViewItem: NSCollectionViewItem, CollectionElementHosting {
    var kind: CollectionElementKind?
    var hostingView: NSHostingView<CollectionElementHostView>?
    var containerView: NSView { view }
    
    static let sectionHeaderElementKind = "section-header-element-kind"
    static let sectionFooterElementKind = "section-footer-element-kind"
    static let sectionBackgroundElementKind = "section-background-element-kind"
    
    func configure(kind: CollectionElementKind, isSelected: Bool) {
        print("CollectionViewItem - configure")
        self.kind = kind
        self.isSelected = isSelected
        updateRootView() }
    
    override func loadView() {
        super.loadView()
        attachIfNeeded() }
    
    override var isSelected: Bool {
        didSet { updateRootView() } }
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet { updateRootView() } }
}

final class CollectionSupplementaryView: NSView, NSCollectionViewElement, CollectionElementHosting {
    var kind: CollectionElementKind?
    var hostingView: NSHostingView<CollectionElementHostView>?
    var containerView: NSView { self }
    
    func configure(kind: CollectionElementKind, isSelected: Bool) {
        print("CollectionSupplementaryView - configure")
       self.kind = kind
        self.isSelected = isSelected
        updateRootView() }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        attachIfNeeded() }
    
    var isSelected: Bool = false {
        didSet { updateRootView() } }
    var highlightState: NSCollectionViewItem.HighlightState = .none {
        didSet { updateRootView() }  }
    var onToggleSelection: (() -> Void) = {
            print("onToggleSelection")
    }
    
    func apply(_ layoutAttributes: NSCollectionViewLayoutAttributes) {
        if layoutAttributes.representedElementKind == "section-background-element-kind" {
            guard let indexPath = layoutAttributes.indexPath else {return}
            self.kind = .background(indexPath: indexPath)
        }
        print("CollectionSupplementaryView - apply:  ", layoutAttributes.representedElementKind ?? "No representedElementKind")
    }
}




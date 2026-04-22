//
//  CollectionViewItems.swift
//  PraxPress
//
//  Created by Elmer Cat on 3/14/26.
//

import SwiftUI
import AppKit

enum CollectionElementKind {
    case pageItem(item: PageItem)
    case editPage(item: PageItem)
    case mergedPage(item: PageItem)
    case header(item: MergedPage)
    case mergedPageHeader(item: MergedPage)
    case footer(item: MergedPage)
    case mergedPageFooter(item: MergedPage)
    case pageItemBackground(indexPath: IndexPath)
    case editPageBackground(indexPath: IndexPath)
    case none
    
}

struct CollectionElementHostView: View {
    let kind: CollectionElementKind
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    var body: some View {
        switch kind {
        case let .pageItem(item):
            PageItemView( pageItem: item, isSelected: isSelected, highlightState: highlightState )
        case let .editPage(item):
            PageEditView(pageItem: item, isSelected: isSelected, highlightState: highlightState )
        case let .mergedPage(item):
            MergedPageView(pageItem: item, isSelected: isSelected, highlightState: highlightState )
        case let .header(item):
            SectionHeaderView(mergedPage: item, isSelected: isSelected, highlightState: highlightState )
        case let .mergedPageHeader(item):
            MergedPageHeaderView(mergedPage: item, isSelected: isSelected, highlightState: highlightState )
        case let .footer(item):
            SectionFooterView(mergedPage: item, isSelected: isSelected, highlightState: highlightState )
        case let .mergedPageFooter(item):
            MergedPageFooterView(mergedPage: item, isSelected: isSelected, highlightState: highlightState )
        case let .pageItemBackground(indexPath):
            PageItemSectionBackgroundView(indexPath: indexPath, isSelected: isSelected, highlightState: highlightState )
        case let .editPageBackground(indexPath):
            EditPageSectionBackgroundView(indexPath: indexPath, isSelected: isSelected, highlightState: highlightState )
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
    
    static let mergedPageHeaderElementKind = "merged-page-header-element-kind"
    static let mergedPageFooterElementKind = "merged-page-footer-element-kind"
    static let sectionHeaderElementKind = "section-header-element-kind"
    static let sectionFooterElementKind = "section-footer-element-kind"
    static let pageItemSectionBackgroundElementKind = "page-item-section-background-element-kind"
    static let editPageSectionBackgroundElementKind = "edit-page-section-background-element-kind"
   
    let preferredFormat = Date.FormatStyle()
        .hour(.defaultDigits(amPM: .omitted))
        .minute()
        .second(.twoDigits)
        .secondFraction(.fractional(3))
    
    func configure(kind: CollectionElementKind, isSelected: Bool) {
        
        switch kind {
        case let .pageItem(item):
            print(Date().formatted(preferredFormat), "CollectionViewItem - configure thumbnail: ", item.name )
        case let .editPage(item):
            print(Date().formatted(preferredFormat), "CollectionViewItem - configure page: ", item.name )
        default:
            print(Date().formatted(preferredFormat), "CollectionViewItem - configure - \(String(describing: kind))")
        }
        
       
        self.kind = kind
        self.isSelected = isSelected
        updateRootView() }
    
    override func loadView() {
        super.loadView()
        attachIfNeeded() }
    
    override func prepareForReuse() {
        print(Date().formatted(preferredFormat), "CollectionViewItem - prepareForReuse - \(String(describing: kind))")
        
        switch kind {
        case let .pageItem(item):
            print("Reusing pageItem(item) - was: \(item.name)")
        case let .editPage(item):
            print("Reusing page(item) - was: \(item.name)")
            
        default:
            break
            
        }
    }
    
    
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: NSCollectionViewLayoutAttributes) -> NSCollectionViewLayoutAttributes {
        let attrs = super.preferredLayoutAttributesFitting(layoutAttributes)
        
  //      print("CollectionViewItem - preferredLayoutAttributesFitting kind: ", kind as Any)
        
        switch kind {
//        case let .pageItem(item):
            
 //       case let .editPage(item):
 //           let width = layoutAttributes.size.width
 //           let height = ceil(width / item.aspectRatio)
 //           attrs.size = CGSize(width: width, height: height)
 //           return attrs

        case let .mergedPage(item):
            let width = layoutAttributes.size.width
            let height = ceil(width / (item.aspectRatio + 0.1))
            attrs.size = CGSize(width: width, height: height)
            return attrs

//        case let .header(item):
            
//        case let .footer(item):
            
//        case let .background(indexPath):
            
        default:
            return attrs

        }
        

    }
    
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
        if layoutAttributes.representedElementKind == "page-item-section-background-element-kind" {
            guard let indexPath = layoutAttributes.indexPath else {return}
            self.kind = .pageItemBackground(indexPath: indexPath)
        }
        else if layoutAttributes.representedElementKind == "edit-page-section-background-element-kind" {
            guard let indexPath = layoutAttributes.indexPath else {return}
            self.kind = .editPageBackground(indexPath: indexPath)
        }
    //    print("CollectionSupplementaryView - apply:  ", layoutAttributes.representedElementKind ?? "No representedElementKind")
    }
}




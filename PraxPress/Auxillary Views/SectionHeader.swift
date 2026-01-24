//
//  SectionHeader.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/24/26.
//


import SwiftUI
import PDFKit

class SectionHeader: NSView, NSCollectionViewElement {
    private var hostingView: NSHostingView<SectionHeaderView>?
    private var indexPath: IndexPath?
    
    func configure(at atIndexPath: IndexPath,
                   isSelected: Bool) {
        indexPath = atIndexPath
        
        let root = SectionHeaderView(indexPath: indexPath!, isSelected: isSelected)
        
        if let hostingView {
            hostingView.rootView = root
        } else {
            let hosting = NSHostingView(rootView: root)
            hosting.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(hosting)
            NSLayoutConstraint.activate([
                hosting.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                hosting.topAnchor.constraint(equalTo: self.topAnchor),
                hosting.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            ])
            self.hostingView = hosting
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            if let indexPath {
                configure(at: indexPath, isSelected: isSelected)
            }
        }
    }
    var onToggleSelection: (() -> Void)?
}

struct SectionHeaderView: View {
    let indexPath: IndexPath
    let isSelected: Bool
    
    func pdfPageItem() -> PDFPageItem? {
        if indexPath.section >= 0,
           indexPath.section < PraxModel.shared.pdfPageSections.count,
           indexPath.item >= 0,
           indexPath.item < PraxModel.shared.pdfPageSections[indexPath.section].pdfPageItems.count {
            return PraxModel.shared.pdfPageSections[indexPath.section].pdfPageItems[indexPath.item]
        } else {
            return nil
        }
    }
    
    var body: some View {
        if let page = pdfPageItem() {
            VStack(spacing: 8) {
                Image(nsImage: page.thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(6)
                HStack {
                    Text(page.name)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Button(action: clickedGuidePageButton) {
                        Image(systemName: "ruler")
                    }
                    .buttonStyle(.borderless)
                    .help("Toggle width guide")
                }
                Text("\(Int(page.trim.left))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .draggable {
                if let data = PraxModel.shared.mergedPDFDocument.dataRepresentation() {
                    return MergedPDFTransfer(data: data)
                } else { return nil}
            }
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
        } else {
            EmptyView()
        }
        
    }
    
    func clickedGuidePageButton() {
        guard let page = pdfPageItem() else { return }
        print("PageItem - clickedGuidePageButton pdfPageItem: \(page.name)")
        if PraxModel.shared.widthGuidePageID == page.id {
            PraxModel.shared.clearWidthGuide()
        } else {
            PraxModel.shared.setWidthGuide(fromPage: page)
        }
    }
}


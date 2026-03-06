//
//  SectionFooter.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/24/26.
//

import SwiftUI

class SectionFooter: NSView, NSCollectionViewElement {
    private var document: MergedPDFDocument?
    private var hostingView: NSHostingView<SectionFooterView>?
    private var indexPath: IndexPath?
    private var pdfPageSection: PDFPageSectionModel?
    
    func configure(for document: MergedPDFDocument?, at atIndexPath: IndexPath,
                   isSelected: Bool) {
        print ("SectionHeader- configure ")
        self.indexPath = atIndexPath
        self.document = document
        guard let indexPath else { fatalError("index path is missing") }
        
        if document!.pageSections.count > indexPath.section {
            let pdfPageSection = document!.pageSections[self.indexPath!.section]
            self.pdfPageSection = pdfPageSection
            
            let root = SectionFooterView(document: document!, pdfPageSection: self.pdfPageSection!, isSelected: isSelected)
            
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
    }
    
    
    var isSelected: Bool = false {
        didSet {
                configure(for: document, at: indexPath!, isSelected: isSelected)
        }
    }
}

struct SectionFooterView: View {
    @Environment(PraxModel.self) private var praxModel
    let document: MergedPDFDocument
    let pdfPageSection: PDFPageSectionModel
    let isSelected: Bool
    
    func mergedSizeText() -> String {
        let section = pdfPageSection
        let w = section.mergedWidthPts
        let h = section.mergedHeightPts
        let wIn = w / 72.0
        let hIn = h / 72.0
        return String(format: "Merged size: %.0f × %.0f pts (%.2f × %.2f in)", w, h, wIn, hIn)
    }
    

 
    var body: some View {
        @Bindable var prax = praxModel
            
            VStack(spacing: 8) {
                HStack {
                    Text("Footer \(pdfPageSection.title)")
                        .font(.caption)
                        .lineLimit(1)
                    Text(mergedSizeText())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
 
            }
            .padding(8)
            .background(PraxGradient())
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .inspector(isPresented: $prax.isLarge) {
                VStack {
                    GroupBox {
                        
                        Text("Inspector 1")
                            .frame(minWidth: 100, maxWidth: 1000, maxHeight: 100)
                            .background(.pink)
                    }
                    .padding(20)
                    //  .background(.yellow)
                    Button(prax.isLarge ? "Make Small" : "Make Large") {
                        // Toggle the state when the button is tapped
                        prax.isLarge.toggle()
                    }
                    Text("Inspector 2")
                    //           .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //               .background(.purple)
                        .background(.purple)
                }
                Text("Inspector 3")
                //    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .inspectorColumnWidth(min: 50, ideal: 150, max: 500)
                    .background(.gray)
            }
        }
}


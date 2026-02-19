//
//  SectionFooter.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/24/26.
//

import SwiftUI

class SectionFooter: NSView, NSCollectionViewElement {
    private var hostingView: NSHostingView<SectionFooterView>?
    private var indexPath: IndexPath?
    
    func configure(at atIndexPath: IndexPath,
                   isSelected: Bool) {
        indexPath = atIndexPath
        
        let root = SectionFooterView(indexPath: indexPath!, isSelected: isSelected)
        
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
}

struct SectionFooterView: View {
    let indexPath: IndexPath
    let isSelected: Bool
    
    func pdfPageSection() -> PDFPageSection? {
        if indexPath.section >= 0,
           indexPath.section < PraxModel.shared.pdfPageSections.count {
            return PraxModel.shared.pdfPageSections[indexPath.section]
        } else {
            return nil
        }
    }
    
    func mergedSizeText() -> String {
        guard let section = pdfPageSection() else { return "Merged size: —" }
        let w = section.mergedWidthPts
        let h = section.mergedHeightPts
        let wIn = w / 72.0
        let hIn = h / 72.0
        return String(format: "Merged size: %.0f × %.0f pts (%.2f × %.2f in)", w, h, wIn, hIn)
    }
    

 
    var body: some View {
        @Bindable var prax = PraxModel.shared
            
            VStack(spacing: 8) {
                HStack {
                    Text("Footer \(indexPath.section + 1)")
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


//
//  SectionHeader.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/24/26.
//

import SwiftUI
import AppKit
import PDFKit
import UniformTypeIdentifiers
/*
struct PDFPageSectionsPayload: Transferable, Codable, Hashable {
    var sections: [PDFPageSection]
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
*/






class SectionHeader: NSView, NSCollectionViewElement {
    private var document: MergedPDFDocument?
    private var hostingView: NSHostingView<SectionHeaderView>?
    private var indexPath: IndexPath?
    private var pdfPageSection: PDFPageSection?
    
    func configure(for document: MergedPDFDocument?, at atIndexPath: IndexPath,
                   isSelected: Bool) {
        print ("SectionHeader- configure ")
        self.indexPath = atIndexPath
        self.document = document
        guard let indexPath else { fatalError("index path is missing") }
        
        if document!.sections.count > indexPath.section {
            let pdfPageSection = document!.sections[self.indexPath!.section]
            self.pdfPageSection = pdfPageSection
            
            let root = SectionHeaderView(document: document!, pdfPageSection: self.pdfPageSection!, isSelected: isSelected)
            
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
    var onToggleSelection: (() -> Void)?
    
}


struct SectionHeaderView: View {
    @Environment(PraxModel.self) private var praxModel
    let document: MergedPDFDocument
    let pdfPageSection: PDFPageSection
    var isSelected: Bool
    
    var body: some View {
        @Bindable var prax = praxModel
        
        let clickGesture = TapGesture()
            .onEnded { value in
                print("View tapped! - \(pdfPageSection.title) - PraxModel.shared.optionKeyPressed: \(prax.optionKeyPressed)")
                clickedSectionHeader()
                
            }
         
        GroupBox {
            Group { Text("Merged Page \(pdfPageSection.title)") }
            
                .draggable({ () -> MergedPDFTransfer? in
                      guard let data = document.mergedPDFDocument.dataRepresentation() else { return nil }
                    return MergedPDFTransfer(data: data, filename: document.exportFilename)
                }()!, preview: {
                    PraxDragPreview()
                })
            

                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .font(.caption)
                .lineLimit(1)
                .padding(8)
            
                .background(Color.black.opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.cyan, lineWidth: 2))
                .gesture(clickGesture)

        }
        .padding(20)
        
        


        /*        .gesture(
            TapGesture()
                .modifiers([.option, .command, .control])
                .onEnded {
                    clickedSectionHeader(modifiers)
                  }
        )
       .gesture(
            TapGesture()
                .modifiers(.command)
                .onEnded {
                    clickedSectionHeader([.command])
                }
        )
        .gesture(
            TapGesture()
                .modifiers(.shift)
                .onEnded {
                    clickedSectionHeader([.shift])
                }
        )
 //       .onTapGesture(perform: clickedSectionHeader())*/
  
        
    }
    
    func clickedSectionHeader(_ modifiers: EventModifiers = [] ) {
        print ("Julie d'Prax - clickedSectionHeader")
        
        if modifiers.contains(.shift) {
            print("Shift + Click detected")
        }
        else if modifiers.contains(.command) {
            print("Command + Click detected")
        }
        else if modifiers.contains(.control) {
            print("Control + Click detected")
        }
        else {
            print("Plain Click detected")
            document.mergedPDFView.go(to: pdfPageSection.pdfPage!)
        }
        
   //     if PraxModel.shared.selectedSections.contains(indexPath.section) {
  //          PraxModel.shared.selectedSections.remove(indexPath.section)
  //      } else {
  //          PraxModel.shared.selectedSections.insert(indexPath.section)
  //      }
        // self.isSelected = PraxModel.shared.selectedSections.contains(indexPath.section)
        // Refresh just this section’s header to reflect the new state.
        //       self.collectionView.reloadSections(IndexSet(integer: indexPath.section))
        
    }
}



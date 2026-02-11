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

struct PDFPageSection: Hashable, Codable, Transferable {
    var title: String
    private(set) var id: UUID = UUID()
    var pdfPage: PDFPage? = nil
    
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    
    var pdfPageItems: [PDFPageItem] = [] {
        didSet {
   //         let prax = oldValue.count
            
            print("\n pdfPageItems didSet: \(self.pdfPageItems.count)\n\n")
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case title
        case id
        case mergedWidthPts
        case mergedHeightPts
        case pdfPageItems
    }
    
    init(
        title: String,
        pdfPage: PDFPage? = nil,
        mergedWidthPts: CGFloat = 0,
        mergedHeightPts: CGFloat = 0,
        pdfPageItems: [PDFPageItem] = []
    ) {
        self.title = title
        self.pdfPage = pdfPage
        self.mergedWidthPts = mergedWidthPts
        self.mergedHeightPts = mergedHeightPts
        self.pdfPageItems = pdfPageItems
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.mergedWidthPts = try container.decode(CGFloat.self, forKey: .mergedWidthPts)
        self.mergedHeightPts = try container.decode(CGFloat.self, forKey: .mergedHeightPts)
        self.pdfPageItems = try container.decode([PDFPageItem].self, forKey: .pdfPageItems)
        // Decode id if present, otherwise generate a new one
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(id, forKey: .id)
        try container.encode(mergedWidthPts, forKey: .mergedWidthPts)
        try container.encode(mergedHeightPts, forKey: .mergedHeightPts)
        try container.encode(pdfPageItems, forKey: .pdfPageItems)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
    
}



struct MergedPDFTransfer: Transferable, Identifiable {
    let id = UUID()
    let data: Data
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        // Provide PDF data so other apps (Mail, Notes, Finder) can accept the drop
        DataRepresentation(exportedContentType: .pdf) { pdf in
            pdf.data
        }
        .suggestedFileName { value in
            value.filename
        }
    }
}


struct PDFPageSectionsPayload: Transferable, Codable, Hashable {
    var sections: [PDFPageSection]
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}







class SectionHeader: NSView, NSCollectionViewElement {
    private var hostingView: NSHostingView<SectionHeaderView>?
    private var indexPath: IndexPath?
    
    
    
    
    func configure(at atIndexPath: IndexPath,
                   isSelected: Bool) {
        indexPath = atIndexPath
        guard let indexPath else { fatalError("index path is missing") }
        
        let root = SectionHeaderView(indexPath: indexPath, isSelected: isSelected)
        
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
    @Environment(PraxContext.self) private var praxContext
    let indexPath: IndexPath
    var isSelected: Bool
    

    
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
    
    enum DragState {
        case inactive
        case pressing
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive, .pressing:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
        
        var isActive: Bool {
            switch self {
            case .inactive:
                return false
            case .pressing, .dragging:
                return true
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .inactive, .pressing:
                return false
            case .dragging:
                return true
            }
        }
    }
    @GestureState private var dragState = DragState.inactive {
        didSet {
            print ("GestureState - dragState: ", dragState)
        }
    }
    
    var body: some View {
        
        let clickGesture = TapGesture()
            .onEnded { value in
                 print("View tapped! - \(indexPath) - praxContext.optionKeyPressed: \(praxContext.optionKeyPressed)")
            }
         

        
        Group { Text("Merged Page \(indexPath.section + 1)") }
        .draggable {
            if let data = PraxModel.shared.mergedPDFDocument.dataRepresentation() {
                return MergedPDFTransfer(data: data, filename: "MergedPage\(indexPath.section + 1).pdf")
            } else { return nil}
        }
        .font(.caption)
        .lineLimit(1)
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(isSelected ? Color.accentColor : Color.cyan, lineWidth: 2))
        .gesture(clickGesture)
        


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
        }
        
        if PraxModel.shared.selectedSections.contains(indexPath.section) {
            PraxModel.shared.selectedSections.remove(indexPath.section)
        } else {
            PraxModel.shared.selectedSections.insert(indexPath.section)
        }
        // self.isSelected = PraxModel.shared.selectedSections.contains(indexPath.section)
        // Refresh just this section’s header to reflect the new state.
        //       self.collectionView.reloadSections(IndexSet(integer: indexPath.section))
        
    }
}



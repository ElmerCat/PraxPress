//
//  Untitled.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/10/26.
//

import SwiftUI
import PDFKit
import TipKit


struct PageItemView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let pageItem: PageItem?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    @State var showSettings = false
    @State private var hoveredButton: Int? = nil
    @State private var dropTargeted: Bool = false
    @State private var hovering: Bool = false

   var body: some View {
        
       let imageSize = prax.thumbnailSize
        let backgroundColor: Color = {
            if dropTargeted { Color.purple }
            else { switch highlightState {
                case .forSelection: Color.orange
                case .forDeselection: Color.green
                case .asDropTarget: Color.purple
                default:
                    if isSelected { Color.blue }
                    else {Color.clear }
                } }}()
        
        let foregroundColor: Color = { switch highlightState {
            case .forSelection: Color.green
            case .forDeselection: Color.orange
            case .asDropTarget: Color.orange
            default:
                if isSelected {Color.white }
                else {Color.blue}
            }}()
        
        if let pageItem {
            GroupBox {
                ZStack {
                    Image(nsImage: pageItem.pdfPage.thumbnail(of: imageSize, for: .cropBox))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    //  .cornerRadius(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding(3)
                        .opacity(pageItem.skipped ? 0.25 : 1.0)
                    
                    Spacer()
                    GroupBox {
                        VStack {
                            HStack {
                                Spacer()
                            
                                Button { document.clickedGuidePageButton(pageItem) }
                                label: { if pageItem.skipped { Image(systemName: "ruler.fill") } else { Image(systemName: "ruler") }}
                                .buttonStyle(PageItemButtonStyle(isHovering: hoveredButton == 235, isOn: document.widthGuidePageID != nil))
                                .onHover { hovering in hoveredButton = hovering ? 235 : nil }
                                .help("Set Width Guide")
                          
                            }
                            Spacer()
                            HStack {
                                
                                Button { document.clickedSkipPageButton(pageItem) }
                                label: { Image(systemName: pageItem.skipped ? "eye.slash.fill" : "eye.slash") }
                                .help(pageItem.skipped ? "Include This Page" : "Skip This Page")
                                .buttonStyle(PageItemButtonStyle(isHovering: hoveredButton == 126, isOn: pageItem.skipped))
                                .onHover { hovering in hoveredButton = hovering ? 126 : nil }
                                

                                Spacer()
                                
                                Button { document.clickedDeletePageButton(pageItem) }
                                label: { Image(systemName: "trash") }
                                    .help("Discard This Page")
                                    .buttonStyle(PageItemButtonStyle(isHovering: hoveredButton == 150))
                                    .onHover { hovering in hoveredButton = hovering ? 150 : nil }
                                
                            }
                            

                        }
                    }
                    .opacity(hovering ? 1 : 0.3)
                    .animation(.easeIn(duration: 0.25), value: hovering)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            
            .onHover { isHovering in
                hovering = isHovering
            }
            
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(foregroundColor, lineWidth: 3) )

            .dropDestination(
                for: PageItemTransfer.self,
                action: {items, location in
                    var itemIDs: Array<UUID> = []
                    for item in items {
                        print("PageItemTransfer - item: ", item)
                        let itemID = item.payload.id
                        itemIDs.append(itemID)
                    }
                    if let indexPath = prax.document.indexPath(for: pageItem) {
                        print("PageItemTransfer itemIDs: ", itemIDs, " - to indexPath: ", indexPath)
                        prax.document.movePageItems(itemIDs: itemIDs, to: indexPath)
                    }
                    return true },
                isTargeted: { targeted in dropTargeted = targeted })

            .foregroundColor(foregroundColor)
            .background(backgroundColor)
        }
         else { EmptyView() }
    }
}


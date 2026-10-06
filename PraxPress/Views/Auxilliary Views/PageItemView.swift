//
//  Untitled.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/10/26.
//

import SwiftUI
import PDFKit
import TipKit
import UniformTypeIdentifiers


struct PageItemView: View {
    //  @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let pageItem: PageItem?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    @State private var viewSize: CGSize = .zero
    @State var showSettings = false
    @State private var dropTargeted: Bool = false
    @State private var dropOperation: DropOperation = .cancel
    @State private var hovering: Bool = false

   var body: some View {
        
       let thumbnailSize = CGSize(width: 170, height: 220)
       
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
                    Image(nsImage: pageItem.pdfPage.thumbnail(of: thumbnailSize, for: .cropBox))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    //  .cornerRadius(6)
                        
                       // .padding(3)
                        .opacity(pageItem.skipped ? 0.25 : 1.0)
                    
             //       Spacer()
                    GroupBox {
                        VStack {
                            HStack {
                                Spacer()
                            
                                Button { prax.document.clickedGuidePageButton(pageItem) }
                                label: { if pageItem.skipped { Image(systemName: "ruler.fill") } else { Image(systemName: "ruler") }}
                                
                                .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 235, isOn: prax.document.widthGuidePageID != nil))
                                .onHover { hovering in prax.hoveredButton = hovering ? 235 : nil }
                                .help("Set Width Guide")
                          
                            }
                            Spacer()
                            HStack {
                                
                                Button { prax.document.clickedSkipPageButton(pageItem) }
                                label: { Image(systemName: pageItem.skipped ? "eye.slash.fill" : "eye.slash") }
                                .help(pageItem.skipped ? "Include This Page" : "Skip This Page")
                                .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 126, isOn: pageItem.skipped))
                                .onHover { hovering in prax.hoveredButton = hovering ? 126 : nil }
                                

                                Spacer()
                                
                                Button(role: .destructive) { prax.document.clickedDeletePageButton(pageItem) }
                                label: { Image(systemName: "trash") }
                                    .help("Discard This Page")
                                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 150))
                                    .onHover { hovering in prax.hoveredButton = hovering ? 150 : nil }
                                
                            }
                            

                        }
                    }
                    .zIndex(1)
//                    .onDrop(of: [.fileURL], delegate: PraxDropDelegate(prax))
                    
                    .environment(\.groupHovering, hovering)
                    .opacity(hovering ? 1 : 0.3)
                    .animation(.easeIn(duration: 0.25), value: hovering)
                }
            
                
          
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .zIndex(11)
            .dropDestination(
                for: PageItem.self,
                action: {items, location in
                    let firstItem = items.first!
                    guard let firstItemIndexPath = prax.document.indexPath(for: firstItem) else { return false}
                    
                    
                    var itemIDs: Array<UUID> = []
                    for item in items {
                        itemIDs.append(item.id)
                    }
                    if var indexPath = prax.document.indexPath(for: pageItem) {
                        if indexPath.section == firstItemIndexPath.section {
                            if indexPath.item == firstItemIndexPath.item + 1 {
                                indexPath.item += 1
                            }
                        }
                        else if location.y > viewSize.height * 0.5 {
                            
                            indexPath.item += 1
                            
                        }
                        if dropOperation == .move {
                            prax.document.movePageItems(itemIDs: itemIDs, to: indexPath)
                        }
                        else if dropOperation == .copy {
                            prax.document.copyPageItems(itemIDs: itemIDs, to: indexPath)
                            
                        }
                    }
                    return true },
                isTargeted: { targeted in dropTargeted = targeted })
            
            .dropConfiguration { dropSession in dropOperation = prax.optionKeyPressed ? .copy : .move
                return DropConfiguration(operation: dropOperation) }
            
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .onGeometryChange(for: CGSize.self) { proxy in proxy.size } action: { newSize in viewSize = newSize }
            
            .onHover { isHovering in hovering = isHovering }
            
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(foregroundColor, lineWidth: 3) )

            .foregroundColor(foregroundColor)
            .background(backgroundColor)
        }
         else { EmptyView() }
    }
}


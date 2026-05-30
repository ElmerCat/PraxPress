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
    
    let praxTheme = PraxTheme(.erika)
    let deleteTheme = PraxTheme(.julie)
    
    @State var showSettings = false
    @State private var hoveredButton: Int? = nil
    
    
    


    
    var body: some View {
        
        
        let imageSize = CGSize(width: 85, height: 110)
        let backgroundColor: Color = {
            switch highlightState {
            case .forSelection:
                Color.orange
            case .forDeselection:
                Color.green
            case .asDropTarget:
                Color.purple
            default:
                if isSelected {
                    Color.blue
                }
                else {
                    Color.clear
                }
            }
        }()
        
        let foregroundColor: Color = {
            switch highlightState {
            case .forSelection:
                Color.green
            case .forDeselection:
                Color.orange
            case .asDropTarget:
                Color.orange
            default:
                if isSelected {
                    Color.white
                }
                else {
                    Color.blue
                }
            }
        }()
        
        if let pageItem {
            GeometryReader { proxy in
                ZStack {
                    GroupBox {
                        Image(nsImage: pageItem.pdfPage.thumbnail(of: imageSize, for: .cropBox))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                          //  .cornerRadius(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .padding(3)
                            .opacity(pageItem.skipped ? 0.25 : 1.0)
                    }
                                            
                    GroupBox {
                        VStack {

                            
                            Button { document.clickedSkipPageButton(pageItem) }
                            label: { Image(systemName: pageItem.skipped ? "text.page.slash" : "text.page") }
                                .help(pageItem.skipped ? "Include This Page" : "Skip This Page")
                                .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 126))
                                .onHover { hovering in hoveredButton = hovering ? 126 : nil }
                                .position(x: proxy.size.width - 30, y: 20)
                            
                            
                            Divider()
                            
                            Button { document.clickedDeletePageButton(pageItem) }
                            label: { Image(systemName: "trash") }
                                .help("Discard This Page")
                                .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 150))
                                .onHover { hovering in hoveredButton = hovering ? 150 : nil }
                                .position(x: proxy.size.width - 30, y: 10)
                            
                        }
                        
                    }
                    
                    
                }
                
                .padding(proxy.size.width * 0.01)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(foregroundColor, lineWidth: 3) )
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                
            }
 //           .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)) // proxy.size.width * 0.01))
            //     .frame(width: proxy.size.width * 0.58)
            //     .position(x: proxy.size.width * 0.72, y: proxy.size.height * 0.5)
            
            //                .inspector(isPresented: $showInspector) {
            //                    PDFPageItemInspector()
            //                }
        }
    
            
//            .background(backgroundColor)
         else {
            EmptyView()
        }
        
    }
}




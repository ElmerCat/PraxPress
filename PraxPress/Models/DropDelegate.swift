//
//  DropDelegate.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/18/26.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct PraxDragPreview: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @State private var rotate = false
    
    let frameSize = CGSize(width: 120, height: 160)
    
    var body: some View {
        
        GroupBox {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("PraxColor").opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.yellow, lineWidth: 2)
                    )
                    .frame(width: frameSize.width, height: frameSize.height - 30)
                

                Image(nsImage: document.mergedPDFDocument.page(at: 0)!.thumbnail(of: frameSize, for: .cropBox))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(6)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .frame(width: frameSize.width - 5, height: frameSize.height - 30, alignment: .trailing)
                
                VStack {
                    HStack {
                        Image("PraxPress")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: frameSize.width - 60, height: frameSize.height - 80, alignment: .leading)
                            .rotationEffect(.degrees(180))
    //                        .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.blue)
                    //        .animation(.easeInOut(duration: 1), value: rotate)
                    //        .onAppear {
                    //            rotate = true
                    //        }
                        
                        Spacer()
                    }
                    
                    
                    
                   Spacer()
                    
                    Text("\(document.exportFilename).pdf")
                        .font(.footnote)
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                      //  .frame(maxWidth: .infinity, alignment: .bottom)
                        .background {
                            Capsule()
                                .foregroundStyle(Color.blue.gradient)
                        }
                    
                }
                
                
            }
        }
        .frame(width: frameSize.width, height: frameSize.height)
        
       
        
                
           
                
                
            
                
                    
            
        
    }
}

#Preview {
    PraxDragPreview()
}


final class PraxDropDelegate: DropDelegate {
    var document: MergedPDFDocument
    var prax: PraxModel
    
    init(_ document: MergedPDFDocument, _ praxModel: PraxModel) {
        self.document = document
        self.prax = praxModel
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        print("DropTargetControl - validateDrop")
        
        if info.hasItemsConforming(to: [.pdfPageDragType, .mergedPageType]) {
            print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.pdfPageDragType, .mergedPageType])")
            return false
        }
        else {
            prax.dropTargeted = true
            return true
        }
    }
    
    func performDrop(info: DropInfo) -> Bool { //  print("DropTargetControl - performDrop")
        prax.dropTargeted = false
        return document.acceptDrop(info.itemProviders(for: [UTType.fileURL]))
    }
    
    func dropEntered(info: DropInfo) {
        print("DropTargetControl - dropEntered")    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        print("DropTargetControl - dropUpdated - phase: ")
        
        if info.hasItemsConforming(to: [.pdfPageDragType, .mergedPageType]) {
            print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.pdfPageDragType, .mergedPageType])")
            return DropProposal(operation: .forbidden)
            
        }
        else if info.hasItemsConforming(to: [UTType.fileURL]) {
            print("DropTargetControl - dropUpdated - hasItemsConforming(to: [UTType.fileURL])")
            return DropProposal(operation: .copy)
        }
        else {
            print("DropTargetControl - dropUpdated - else ")
            return DropProposal(operation: .forbidden)
        }
    }
    
    func dropExited(info: DropInfo) {
        print("DropTargetControl - dropExited")
        prax.dropTargeted = false
    }
    
    
}

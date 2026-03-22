//
//  DropDelegate.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/18/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct PraxDragPreview: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @State private var rotate = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("PraxColor").opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
                .frame(width: 85, height: 110)
            
            VStack(spacing: 6) {
                
                Image("PraxPress")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(.degrees(rotate ? 180 : 0))
                Text("\(document.exportFilename).pdf")
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
            }
        }
        .font(.system(size: 28, weight: .medium))
        .foregroundStyle(.blue)
        .frame(width: 85, height: 110)
        .animation(.easeInOut(duration: 1), value: rotate)
        .onAppear {
            rotate = true
        }
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

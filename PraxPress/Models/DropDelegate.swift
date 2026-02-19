//
//  DropDelegate.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/18/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct PraxDragPreview: View {
    
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
                Text("\(PraxModel.shared.exportFilename).pdf")
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

    func validateDrop(info: DropInfo) -> Bool {
        print("DropTargetControl - validateDrop")
        
        if info.hasItemsConforming(to: [.pdfPageDragType, .pdfPageSectionType]) {
            print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.pdfPageDragType, .pdfPageSectionType])")
            return false
        }
        else {
            PraxModel.shared.dropTargeted = true
            return true
        }
    }
    
    func performDrop(info: DropInfo) -> Bool { //  print("DropTargetControl - performDrop")
        PraxModel.shared.dropTargeted = false
        return PraxModel.shared.acceptDrop(info.itemProviders(for: [UTType.fileURL]))
    }
    
    func dropEntered(info: DropInfo) {
        print("DropTargetControl - dropEntered")    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        print("DropTargetControl - dropUpdated - phase: ")
        
        if info.hasItemsConforming(to: [.pdfPageDragType, .pdfPageSectionType]) {
            print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.pdfPageDragType, .pdfPageSectionType])")
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
        PraxModel.shared.dropTargeted = false
    }
    
    
}

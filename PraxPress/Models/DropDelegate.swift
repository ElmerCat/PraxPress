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
        
        if document.mergedPDFDocument.pageCount > 0 {
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
        else {
            EmptyView()
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
        
        
        print("PraxDropDelegate performDrop(info: DropInfo)  ", info)
        
        let providers = info.itemProviders(for: [UTType.fileURL])
        
        
        for provider in providers {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { [self] (data, error) in
                if let data = data,
                   let path = String(data: data, encoding: .utf8),
                   let url = URL(string: path) {
                    
                    print("Julie Belanger path = ", path, "  URL: ", url)
                    
                    
                    let ext = url.pathExtension.lowercased()
                    
                    switch (ext) {
                    case "pdf":
                        
                        DispatchQueue.main.async { [self] in
                            document.addPagesFromURL(url, to: nil) }
                        
                        Task { do { try await
                            document.persistence.processImportedURLs([url]) }
                            catch { fatalError("It didn't work") } }
                        
                    case "png", "jpeg", "jpg", "gif", "heic":
                       
                        if prax.inspectNextImageDrop {
                            
                            if let image = NSImage(contentsOf: url) {
                                prax.inspectingImage = image
                                prax.showingImageDropInspector = true

                                var imageSize = image.size
                                
                                print ("case png heic ", image.size)
                                

                            }
                            
                            else { print("Failed to open Image at \(url)") }
                            
                            
                        }
                        else {
                            DispatchQueue.main.async { [self] in
                                document.addPageFromImageURL(url, to: nil) }

                        }
                        
                        
                        
                    default:
                        break
                        
                    } }
                    
        } }
        
        prax.dropTargeted = false
        return true
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

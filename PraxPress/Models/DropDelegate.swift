//
//  DropDelegate.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/18/26.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit



extension NSPasteboard.PasteboardType {
    static let pdfPageDragType = NSPasteboard.PasteboardType("com.praxpress.pdf-page-item")
    static let mergedPageType = NSPasteboard.PasteboardType("com.praxpress.pdf-page-section")
    static let pdfFileType = NSPasteboard.PasteboardType("com.praxpress.pdf-file-item")
}

extension UTType {
    static let pdfPageDragType = UTType(exportedAs: "com.praxpress.pdf-page-item")
    static let mergedPageType = UTType(exportedAs: "com.praxpress.pdf-page-section")
    static let pdfFileType = UTType(exportedAs: "com.praxpress.pdf-file-item")
}

final class PraxDropDelegate: DropDelegate {
    var document: MergedPDFDocument
    var prax: PraxModel
    
    init(_ document: MergedPDFDocument, _ praxModel: PraxModel) {
        self.document = document
        self.prax = praxModel
    }
    
    func dropEntered(info: DropInfo) {
        print("DropTargetControl - dropEntered")    }

    
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

        if info.hasItemsConforming(to: [.pdfFileType]) {
           for provider in info.itemProviders(for: [UTType.pdfFileType]) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.pdfFileType.identifier) { [self] (data, error) in
                    if let data = data {  Task {  struct Payload: Codable {
                        let fileURL: URL
                        let bookmarkData: Data }; do {
                        let payload = try JSONDecoder().decode(Payload.self, from: data)
                        await prax.receiveDroppedURL(payload.fileURL, bookmarkData: payload.bookmarkData) }
                        catch { print("failed to decode Payload ") } }}
                    else { print("no data for forTypeIdentifier: UTType.pdfFileType.identifier")}}}}
        
        else if info.hasItemsConforming(to: [.fileURL]) {
            for provider in info.itemProviders(for: [UTType.fileURL]) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { [self] (data, error) in
                    if let data = data,
                       let path = String(data: data, encoding: .utf8),
                       let url = URL(string: path) {
                       print("Julie Belanger path = ", path, "  URL: ", url)
                       prax.receiveDroppedURL(url) }}}}

        else { return false }
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
  //      print("DropTargetControl - dropUpdated - phase: ")
        
        if info.hasItemsConforming(to: [.pdfPageDragType]) {
  //          print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.pdfPageDragType])")
            return DropProposal(operation: .forbidden)
            
        }
        else if info.hasItemsConforming(to: [.mergedPageType]) {
  //          print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.mergedPageType])")
            return DropProposal(operation: .forbidden)
            
        }
        else if info.hasItemsConforming(to: [.pdfFileType]) {
  //          print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.pdfFileType])")
            return DropProposal(operation: .copy)
            
        }
        else if info.hasItemsConforming(to: [UTType.fileURL]) {
    //        print("DropTargetControl - dropUpdated - hasItemsConforming(to: [UTType.fileURL])")
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


class FilePromiseProvider: NSFilePromiseProvider, NSFilePromiseProviderDelegate {
    
    var pdfDocument: PDFDocument?
    var fileName: String = "PraxPress-Prax.pdf"
    
    struct UserInfoKeys {
        static let indexPathKey = "indexPath"
        static let urlKey = "url"
    }
    
    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types = super.writableTypes(for: pasteboard)
        types.append(.pdfPageDragType) // Add our own internal drag type (row drag and drop reordering).
        types.append(.mergedPageType) // Add our own internal drag type (row drag and drop reordering).
        types.append(.fileURL) // Add the .fileURL drag type (to promise files to other apps).
        return types
    }
    
    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        guard let userInfoDict = userInfo as? [String: Any] else { return nil }
        switch type {
        case .fileURL:
            // Incoming type is "public.file-url", return (from our userInfo) the item's URL.
            if let url = userInfoDict[FilePromiseProvider.UserInfoKeys.urlKey] as? NSURL {
                return url.pasteboardPropertyList(forType: type)
            }
        case .mergedPageType:
            print ("mergedPageType")
            // Incoming type is "com.mycompany.mydragdrop", return (from our userInfo) the item's indexPath.
            let indexPathData = userInfoDict[FilePromiseProvider.UserInfoKeys.indexPathKey]
            return indexPathData

        case .pdfPageDragType:
            // Incoming type is "com.mycompany.mydragdrop", return (from our userInfo) the item's indexPath.
            let indexPathData = userInfoDict[FilePromiseProvider.UserInfoKeys.indexPathKey]
            return indexPathData
        default:
            break
        }
        return super.pasteboardPropertyList(forType: type)
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        
        print("filePromiseProvider fileNameForType: ", fileType)
        return fileName
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL) async throws {
        
        print("filePromiseProvider writePromiseTo url:  ", url)
        pdfDocument?.write(to: url)
        
    }
    
}


struct DropTargetControl: View {
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    
    var body: some View {
        @Bindable var prax = praxModel
        
        Group {
            HStack {
                Spacer(minLength: 25)
                Text("   Drop Files Here   ")
                    .font(.headline)
                    .padding(.vertical, 10)
                
                    .foregroundStyle(.white)
                
                    .contentShape(.rect)
                
                Button {
                    prax.showingFileImportOptions.toggle()
                } label: {
                    Label("Import Options", systemImage: (prax.showingMergedDocumentInspector ? "gearshape.fill" : "gearshape"))
                }
                .sheet(isPresented: $prax.showingFileImportOptions) {
                    ImportOptionsInspector()
                    
                        .presentationDetents(
                            [.height(120), .medium, .large])
                        .presentationBackgroundInteraction(
                            .enabled(upThrough: .height(120)))
                        .presentationSizing(.form)
                    
                    
                }
                Spacer(minLength: 25)
            }.background {
                Capsule()
                    .foregroundStyle(prax.dropTargeted ? Color.green.gradient : Color.blue.gradient )
            }
        }
        .popover(isPresented: $prax.showingImageDropInspector) { ImageInspectingPopover() }
        
        .onDrop(of: [.fileURL, .pdfFileType, .mergedPageType, .pdfPageDragType], delegate: PraxDropDelegate(document, prax))
        
        
    }
}





struct DragOutControl: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    @FocusState private var isFocused: Bool
    // 2. Track the text selection
    @State private var selection: TextSelection?
    
    var body: some View {
        @Bindable var prax = praxModel
        
        Group {
            HStack {
                Spacer(minLength: 25)
                Text("Drag out")
                    .font(.headline)
                    .padding(.vertical, 10)
                
                    .foregroundStyle(.white)
                
                    .contentShape(.rect)
                
                Spacer(minLength: 5)
                Image(systemName: "arrow.right.doc.on.clipboard")
                
                Spacer(minLength: 5)
                Text(String("\(document.exportFilename).pdf"))
                    .font(.system(size: 10, weight: .ultraLight, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .center))

                Spacer(minLength: 25)
            }
            .draggable({ () -> MergedPDFTransfer? in
                guard let data = document.mergedPDFDocument.dataRepresentation() else { return nil }
                return MergedPDFTransfer(data: data, filename: document.exportFilename)
            }()!, preview: {
                PraxDragPreview()
            })
            
            
            .background {
                Capsule()
                    .foregroundStyle(Color.blue.gradient)
            }
        }
        
        .onAppear {
           
            isFocused = true
        }

    }
}



struct PraxDragPreview: View {
    @Environment(PraxModel.self) var prax: PraxModel
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @State private var rotate = false
    
    let frameSize = CGSize(width: 120, height: 160)
    
    var body: some View {
        

        
        if document.mergedPDFDocument.pageCount > 0 {
            GroupBox {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(prax.annotationSaveMode.color.opacity(0.75))
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
                                .foregroundStyle(prax.annotationSaveMode.color)
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


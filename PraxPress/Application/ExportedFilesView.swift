//
//  MergedPDFDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/8/26.
//


//
//  MergedDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/12/26.
//

import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers


struct ExportedFilesView: View {
    @Environment(PraxModel.self) private var prax
    @Query(filter: #Predicate{ $0.name == "Main File Group"}, sort: \SourceFileGroup.name, ) private var sourceFileGroups: [SourceFileGroup]
    @Query() private var sourceFiles: [SourceFile]
    
    @AppStorage("exportFolderBookmark") private var exportFolderBookmark: Data?
    @State private var hovering: Bool = false
    
    var body: some View {
        @Bindable var prax = prax
        
        VStack(alignment: .leading, spacing: 16) {
            ExportedFilesToolbarView()
            GroupBox {
                SourceFilesTable("Exported File Group")
                Text("\(prax.selectedFiles.count)  of \(sourceFiles.count) Files Selected")
                    .font(.subheadline)
            }.frame(minHeight: 200)
            
            
            Button (action: { prax.showFileImporter = true  }, label: {
                HStack{ Image(systemName: "plus.rectangle.on.folder")
                    Text("Click to Select Files") }.fontWeight(.bold).fontWidth(.expanded) })
            .buttonStyle(.borderedProminent)
            .buttonSizing(.flexible)
            //          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
        }
        .onDrop(of: [.fileURL], delegate: PraxDropDelegate(prax))
        
        .onAppear {
            if let bookmark = exportFolderBookmark {
                var isStale = false
                guard let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                else { let praxError = PraxError.bookmarkResolutionFailed(underlyingError: nil); prax.presentError(praxError); return }
                prax.exportFolderURL = url
            }
        }
        .onChange(of: prax.exportFolderURL) {
            Task {
                print (".onChange(of: prax.exportFolderURL)  ", prax.exportFolderURL as Any)
                guard let url = prax.exportFolderURL else { return }
                
                let needsStop = url.startAccessingSecurityScopedResource()
                defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
                
                guard let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) else {
                    let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Error reading file bookmark data" ])
                    let praxError = PraxError.fileImportFailed(fileName: url.absoluteString, underlyingError: error)
                    prax.presentError(praxError)
                    return
                }
                exportFolderBookmark = data

            }
        }
        .fileImporter(
            isPresented: $prax.showExportFolderSelector,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false ) { result in
                
                switch result {
                case .success(let urls):
                    prax.exportFolderURL = urls.first
                    guard let url = urls.first else { return }
                    
                    let needsStop = url.startAccessingSecurityScopedResource()
                    defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
                    
                    guard let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) else {
                        let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Error reading file bookmark data" ])
                        let praxError = PraxError.fileImportFailed(fileName: url.absoluteString, underlyingError: error)
                        prax.presentError(praxError)
                        return
                    }
                    prax.exportFolderBookmark = data
                    prax.exportFolderURL = url
                    
                default :
                    return
                }
                
            }
            .fileDialogDefaultDirectory(prax.document.sourceFolderURL)
            .fileDialogMessage("Choose the Export File Folder")
            .fileDialogConfirmationLabel(Text("Choose Folder"))
            .fileDialogCustomizationID("ChooseExportFolderDialog")
        
        
    }
}

struct DocumentView: View {
    @Environment(PraxModel.self) private var prax
    @State private var editingDocumentVersion: UUID = UUID()
    
    
    
    var body: some View {
        HStack {
            Spacer()
            ScrollView(prax.scrollViewParameters().axes, showsIndicators: true) {
                
                VStack(spacing: 30) {
                    ForEach(0..<prax.document.pageImages.count, id: \.self) { index in
                        let img = prax.document.pageImages[index]
                        let size = img.size
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size.width * prax.mergedViewScaleFactor,
                                   height: size.height * prax.mergedViewScaleFactor)
                    }
                }
            }
            Spacer()
        }
        
        .onChange(of: prax.document.mergedPDFDocument) {
            
            if editingDocumentVersion != prax.document.editingDocumentVersion {
                editingDocumentVersion = prax.document.editingDocumentVersion
                prax.scaleMergedView()
            }
        }
        
        .onGeometryChange(for: CGSize.self) { viewGeometry in return viewGeometry.size }
        action: { oldValue, newValue in prax.mergedViewSize = newValue }
    }
}




struct ExportedFilesToolbarView: View {
    @Environment(PraxModel.self) private var prax
    @FocusState private var focusedField: FieldName?
    
    var body: some View {
        @Bindable var prax = prax
        //      let _ = Self._printChanges()
        VStack {
            Text("Exported Files")
            
            Divider()
            Text(String("Export Folder: \(prax.exportFolderURL?.path ?? "<none>")"))
            
            Spacer()
            
            HStack {
                
                Button(role: .confirm, action: { prax.showExportFolderSelector.toggle() }, label: {
                    Image(systemName: "folder") })
                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 1041))
                .onHover { hovering in prax.hoveredButton = hovering ? 1041 : nil }
                
                
                PraxButton(action: {export()}, symbol: "arrow.down.document", help: "Export")
                    .padding(.horizontal, 10)
                    .disabled(prax.exportFolderURL == nil)
                Spacer()
                
            }
            
        }
        
        
    }
    
    private func export() {
        if !prax.document.exportFilename.isEmpty {
            let filename = prax.document.exportFilename + "." + prax.document.exportFilenameExtension
            
            var isStale = false
            guard let data = prax.exportFolderBookmark, var url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            else { let praxError = PraxError.bookmarkResolutionFailed(underlyingError: nil); prax.presentError(praxError); return }
            
            let needsStop = url.startAccessingSecurityScopedResource(); defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            
            url.appendPathComponent(filename, isDirectory: true)
            
            if !prax.document.mergedPDFDocument.write(to: url) {
                let praxError = PraxError.saveFailed(reason: "Failed to save:  \(url.deletingPathExtension())", underlyingError: nil); prax.presentError(praxError) }
            Task { await prax.persistence?.addExportedSourceFile(url) }
            
        }
        
        
    }
    
    
    
    
}

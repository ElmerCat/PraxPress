//
//  SourceFilesView.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//
import SwiftUI
import PDFKit
import UniformTypeIdentifiers
internal import Combine

private let DEBUG_LOGS = false


struct SourceFilesView: View {
    
    @Environment(ViewModel.self) private var _viewModel
    @State private var importError: String?
    
    var body: some View {
        @Bindable var viewModel = _viewModel
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                if !viewModel.listOfFiles.isEmpty {
                    
                    
                    Table(viewModel.listOfFiles, selection: $viewModel.selectedFiles) {
                        TableColumn("File") { entry in Text(entry.fileName) }
                        TableColumn("PcardHolderName") { entry in Text(entry.pcardHolderName ?? "—") }
                        TableColumn("DocumentNumber") { entry in Text(entry.documentNumber ?? "—") }
                        TableColumn("Date") { entry in Text(entry.date ?? "—") }
                        TableColumn("Amount") { entry in Text(entry.amount ?? "—") }
                        TableColumn("Vendor") { entry in Text(entry.vendor ?? "—") }
                        TableColumn("GLAccount") { entry in Text(entry.glAccount ?? "—") }
                        TableColumn("CostObject") { entry in Text(entry.costObject ?? "—") }
                        TableColumn("Description") { entry in Text(entry.description ?? "—") }
                    }
                    .frame(minHeight: 200)
                     
                    Text("\(viewModel.selectedFiles.count)  of \(viewModel.listOfFiles.count) Files Selected")
                        .font(.subheadline)
                       

                } else {
                    
                    Button (action: {
                        viewModel.showingImporter = true
                    }, label: {
                        HStack{
                            Image(systemName: "plus.rectangle.on.folder")
                            Text("Click to Select Files")
                        }
                        .fontWeight(.bold)
                        .fontWidth(.expanded)
                    })
                    .buttonStyle(.borderedProminent)
                    .buttonSizing(.flexible)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
                }
                
            }
            .background(Color.blue.opacity(0.5))
        }
        .navigationTitle("PraxPress")
        .navigationSplitViewColumnWidth(min: 100, ideal: 300, max: 1000)
        .toolbar(removing: .sidebarToggle)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if (viewModel.columnVisibility == .all && !viewModel.selectedFiles.isEmpty) {
                    Button {
                        viewModel.listOfFiles.removeAll()
                        viewModel.selectedFiles.removeAll()
                    } label: {
                        Label("Remove Files", systemImage: "folder.badge.minus")
                    }
                    .disabled(viewModel.selectedFiles.isEmpty)
                }
            }
        }
        .fileImporter(
            isPresented: $viewModel.showingImporter,
            allowedContentTypes: [.pdf, .folder],
            allowsMultipleSelection: true
        ) { result in
            handleImportResult(result, forFiles:&viewModel.listOfFiles)
        }
    }
  
    private func handleImportResult(_ result: Result<[URL], Error>, forFiles: inout [PDFEntry]){
        switch result {
        case .success(let urls):
            processImportedURLs(urls, listOfFiles: &forFiles)
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
    
    private func processImportedURLs(_ urls: [URL], listOfFiles: inout [PDFEntry]) {
        var seen = Set<URL>(listOfFiles.map { $0.url })
        
        func filesRecursively(in folderURL: URL) -> [URL] {
            var collected: [URL] = []
            let fm = FileManager.default
            if let enumerator = fm.enumerator(at: folderURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let item as URL in enumerator {
                    do {
                        let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])
                        if resourceValues.isDirectory == true {
                            continue
                        } else {
                            if DEBUG_LOGS { print("Discovered file in folder: \(item.path)") }
                            collected.append(item)
                        }
                    } catch {
                        continue
                    }
                }
            }
            return collected
        }
        
        func extractFormFields(from bookmarkData: Data) -> PDFEntry? {
            var isStale = false
            guard let resolvedURL = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else {
                if DEBUG_LOGS { print("Failed to resolve bookmark") }
                return nil
            }
            
            let needsStop = resolvedURL.startAccessingSecurityScopedResource()
            defer { if needsStop { resolvedURL.stopAccessingSecurityScopedResource() } }
            
            if DEBUG_LOGS { print("\n--- Parsing PDF: \(resolvedURL.absoluteString) ---") }
            guard let doc = PDFDocument(url: resolvedURL) else {
                if DEBUG_LOGS { print("Failed to open PDF: \(resolvedURL.path)") }
                return nil
            }
            if DEBUG_LOGS { print("Opened PDF. Page count: \(doc.pageCount)") }
            
            var pcardHolderName: String?
            var documentNumber: String?
            var date: String?
            var amount: String?
            var vendor: String?
            var glAccount: String?
            var costObject: String?
            var description: String?
            
            func value(from annot: PDFAnnotation) -> String? {
                if let v = annot.widgetStringValue, !v.isEmpty { return v }
                if let v = annot.contents, !v.isEmpty { return v }
                return nil
            }
            
            for pageIndex in 0..<doc.pageCount {
                guard let page = doc.page(at: pageIndex) else { continue }
                if DEBUG_LOGS { print("Page #\(pageIndex + 1): annotations=\(page.annotations.count)") }
                for annot in page.annotations {
                    let key = annot.fieldName ?? ""
                    if key.isEmpty { continue }
                    let widgetType = String(describing: annot.widgetFieldType)
                    let extracted = value(from: annot) ?? "(nil)"
                    if DEBUG_LOGS { print("  Annotation field=\(key) type=\(widgetType) value=\(extracted)") }
                    
                    if let v = value(from: annot), !(v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        switch key {
                        case "PcardHolderName":
                            if pcardHolderName == nil { pcardHolderName = v }
                        case "DocumentNumber":
                            if documentNumber == nil { documentNumber = v }
                        case "Date":
                            if date == nil { date = v }
                        case "Amount":
                            if amount == nil { amount = v }
                        case "Vendor":
                            if vendor == nil { vendor = v }
                        case "GLAccount":
                            if glAccount == nil { glAccount = v }
                        case "CostObject":
                            if costObject == nil { costObject = v }
                        case "Description":
                            if description == nil { description = v }
                        default:
                            break
                        }
                    }
                }
            }
            
            if DEBUG_LOGS {
                print("Captured -> Holder=\(pcardHolderName ?? "nil"), Doc#=\(documentNumber ?? "nil"), Date=\(date ?? "nil"), Amount=\(amount ?? "nil"), Vendor=\(vendor ?? "nil"), GL=\(glAccount ?? "nil"), CostObject=\(costObject ?? "nil"), Desc=\(description ?? "nil"))")
            }
            
            return PDFEntry(
                url: resolvedURL,
                bookmarkData: bookmarkData,
                pcardHolderName: pcardHolderName,
                documentNumber: documentNumber,
                date: date,
                amount: amount,
                vendor: vendor,
                glAccount: glAccount,
                costObject: costObject,
                description: description
            )
        }
        
        var expanded: [(url: URL, bookmark: Data)] = []
        for url in urls {
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let values = try url.resourceValues(forKeys: [.isDirectoryKey])
                if values.isDirectory == true {
                    let discovered = filesRecursively(in: url)
                    for fileURL in discovered {
                        guard isPDF(fileURL) else { continue }
                        if let data = try? fileURL.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                            expanded.append((url: fileURL, bookmark: data))
                        }
                    }
                } else {
                    if isPDF(url), let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                        expanded.append((url: url, bookmark: data))
                    }
                }
            } catch {
                if isPDF(url), let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                    expanded.append((url: url, bookmark: data))
                }
            }
        }
        
        let uniquePairs: [(url: URL, bookmark: Data)] = expanded.filter { pair in
            seen.insert(pair.url).inserted
        }
        
        let entries: [PDFEntry] = uniquePairs.compactMap { pair in
            return extractFormFields(from: pair.bookmark)
        }
        listOfFiles.append(contentsOf: entries)
    }
}

#Preview {
    SourceFilesView()
}


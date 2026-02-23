//
//  SourceFilesView.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//
import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers
//import Combine

private let DEBUG_LOGS = true


struct PDFFilesList: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument


    var body: some View {
        @Bindable var document = document
         
        Group {
            Table(document.pdfFiles, selection: $document.selectedFiles) {
                TableColumn("File") { (entry: PDFFile) in
                    let value = entry.fileName
                    Text(value)
                }
                TableColumn("Pages") { (entry: PDFFile) in
                    let value = entry.pageCount
                    Text(String(value))
                }
                TableColumn("PcardHolderName") { (entry: PDFFile) in
                    let value = entry.dataFields?.pcardHolderName ?? "—"
                    Text(value)
                }
                TableColumn("DocumentNumber") { (entry: PDFFile) in
                    let value = entry.dataFields?.documentNumber ?? "—"
                    Text(value)
                }
                TableColumn("Date") { (entry: PDFFile) in
                    let value = entry.dataFields?.date ?? "—"
                    Text(value)
                }
                TableColumn("Amount") { (entry: PDFFile) in
                    let value = entry.dataFields?.amount ?? "—"
                    Text(value)
                }
                TableColumn("Vendor") { (entry: PDFFile) in
                    let value = entry.dataFields?.vendor ?? "—"
                    Text(value)
                }
                TableColumn("GLAccount") { (entry: PDFFile) in
                    let value = entry.dataFields?.glAccount ?? "—"
                    Text(value)
                }
                TableColumn("CostObject") { (entry: PDFFile) in
                    let value = entry.dataFields?.costObject ?? "—"
                    Text(value)
                }
                TableColumn("Justification") { (entry: PDFFile) in
                    let value = entry.dataFields?.justification ?? "—"
                    Text(value)
                }
            }
        }
    }
}



/*
 ZStack {
 RoundedRectangle(cornerRadius: 10)
 .fill(Color.accentColor.opacity(0.15))
 .overlay(
 RoundedRectangle(cornerRadius: 10)
 .stroke(Color.accentColor, lineWidth: 2)
 )
 .frame(width: 180, height: 80)
 
 VStack(spacing: 6) {
 Image(systemName: "doc.text.fill")
 .font(.system(size: 28, weight: .medium))
 .foregroundStyle(.blue)
 Text("\(prax.exportFilename).pdf")
 .font(.footnote)
 .foregroundStyle(.primary)
 .lineLimit(1)
 .padding(.horizontal, 8)
 }
 }
 */



struct SourceFilesView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    //   @State private var prax = PraxModel.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(PraxModel.self) private var praxModel
    @Query(sort: \PDFFileGroup.name) private var pdfFileGroups: [PDFFileGroup]
    //    @Query(sort: \PDFFile.filename) private var pdfFiles: [PDFFile]
    
    @State private var importError: String?
    
    
    
    var body: some View {
        @Bindable var prax = praxModel
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                if !document.pdfFiles.isEmpty {
                    HStack {
                        Button {
                            prax.showingImporter = true
                        } label: {
                            Label("Add Files", systemImage: "folder.badge.plus")
                        }
                        
                        if !document.selectedFiles.isEmpty {
                            Button {
                                document.deleteSelectedFilesFromDatabase()
                            } label: {
                                Label("Remove Files", systemImage: "folder.badge.minus")
                            }
                            .disabled(document.selectedFiles.isEmpty)
                        }

                    }
                    VSplitView {
                       
                        GroupBox {
                            PDFFilesList()
                            
                            Text("\(document.selectedFiles.count)  of \(document.pdfFiles.count) Files Selected")
                                .font(.subheadline)
                        }
                        .frame(minHeight: 200)
                        
                    }
                    
                    
                } else {
                    
                    Button (action: {
                        prax.showingImporter = true
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
        

        .fileImporter(
            isPresented: $prax.showingImporter,
            allowedContentTypes: [.pdf, .folder],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                processImportedURLs(urls) //, listOfFiles: &forFiles)
            case .failure(let error):
                importError = error.localizedDescription
            }
            //            handleImportResult(result, forFiles:&prax.listOfFiles)
        }
        
        .task {
            DispatchQueue.main.async {
                print ("Fortunareed")
          }
        }
  
        .onAppear() {
            print ("Sharon Eldon")
        }
        
        .onDisappear() {
            print ("Marsha Nolan")
        }
        
    }
    

    
    private func pdfFileGroup(_ name: String) -> PDFFileGroup {
        if let fileGroup = pdfFileGroups.first(where: { $0.name == name }) {
            return fileGroup
        }
        else {
            let fileGroup = PDFFileGroup(name: name)
            modelContext.insert(fileGroup)
            do {
                try  modelContext.save()
                
            } catch {
                fatalError(error.localizedDescription)
            }
            return fileGroup
        }
    }
    
    
    /*
     private func handleImportResult(_ result: Result<[URL], Error>, forFiles: inout [PDFEntry]){
     switch result {
     case .success(let urls):
     processImportedURLs(urls, listOfFiles: &forFiles)
     case .failure(let error):
     importError = error.localizedDescription
     }
     }
     */
    
    private func processImportedURLs(_ urls: [URL]) //, listOfFiles: inout [PDFEntry]) {
    {
        
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
        var seen = Set<URL>(document.pdfFiles.map { $0.url })
        
        
        let uniquePairs: [(url: URL, bookmark: Data)] = expanded.filter { pair in
            seen.insert(pair.url).inserted
        }
        
        let entries: [PDFEntry] = uniquePairs.compactMap { pair in
            return extractFormFields(from: pair.bookmark)
        }
        
        let mainFileGroup = pdfFileGroup("Main File Group")
        
        entries.forEach { entry in
            
            if !document.pdfFiles.contains(where: { $0.url == entry.url }) {
                let pdfFile = PDFFile(fileGroup: mainFileGroup, url: entry.url, bookmarkData: entry.bookmarkData, pageCount: entry.pageCount)
                pdfFile.dataFields = pdfFile.dataFieldsFromEntry(entry)
                modelContext.insert(pdfFile)
            }
        }
        
        
        
        
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
                pageCount: doc.pageCount,
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
        
        
    }
}

#Preview {
   
    SourceFilesView()
}


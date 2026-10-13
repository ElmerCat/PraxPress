//
//  SourceFilesListRow.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/9/26.
//

import SwiftUI

struct SourceFilesListRow: View {
    init(_ sourceFile: SourceFile) { self.sourceFile = sourceFile }
    let sourceFile: SourceFile
    
    @Environment(PraxModel.self) private var prax
    @Environment(\.dismiss) private var dismiss
    
    func backgroundColor() -> Color {
        if sourceFile.fileGroup.name == FileGroup.locked.rawValue { return .cyan }
        switch sourceFile.status {
        case .bad: return .black
        case .trashed: return .red
        case .okay: switch sourceFile.fileType {
        case .pdf: return .blue
        case .image: return .brown
        case .text: return .green
            case .other: return .gray } }
    }
    
    @State private var fileSize: Int64 = 0
    @State private var creationDate: Date = .distantPast
    @State private var modificationDate: Date = .distantPast
    
    var body: some View {
        @Bindable var prax = prax
        GroupBox {
            HStack {
                Image(.pdfMenuIcon)
                    .foregroundColor(.gray)
                    .overlay(alignment: .topTrailing) {
                        if sourceFile.pageCount < 2 {  EmptyView() }  else {
                            Text(String(sourceFile.pageCount))
                            .foregroundColor(.black).padding(4).background(Color.red, in: Circle()).offset(x: 5, y: -5) }  }
                
                Text(sourceFile.fileName)
                
                Spacer()
                
                if sourceFile.dataFields?.isEmpty == false {
                    Image(systemName: "list.bullet.rectangle").resizable(capInsets: EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1), resizingMode: .stretch).frame(maxWidth:20).foregroundStyle(.buttonDefaultBackground) }
                
                if sourceFile.status == .bad { Text("This file cannot be found").foregroundColor(.red); Spacer() }
                else {
                    if sourceFile.status == .trashed { Text("In Trash").foregroundColor(.red); Spacer() }
                    
                    PraxButton(action: { prax.document.addPagesFromSourceFile(sourceFile) }, symbol: "inset.filled.trailinghalf.arrow.trailing.rectangle", help: "Trim and Merge File Pages") }
            }
        }
        .onChange(of: sourceFile) { Task  { do { let fileAttributes = try await fileAttributesForBookmark(sourceFile.bookmarkData)
            
            print(fileAttributes)
            print(".size: ", fileAttributes[.size] ?? 0)
            print(".creationDate: ", fileAttributes[.creationDate] ?? 0)
            print(".modificationDate: ", fileAttributes[.modificationDate] ?? 0)
            
            fileSize = fileAttributes[.size] as? Int64 ?? 0
            creationDate = fileAttributes[.creationDate] as? Date ?? .distantPast
            modificationDate = fileAttributes[.modificationDate] as? Date ?? .distantPast
            
        } catch { print(error.localizedDescription) } }}
        
        
        .lineLimit(1) //.font(.system(size: 12))
        .background(backgroundColor())
        .padding(0)
        .draggable {
            return SourceFileTransfer(sourceFile: sourceFile)
        }
        
        .focusable()
        
        .onTapGesture(count: 1) {prax.selectedSourceFile = sourceFile}  //sourceFile.testBookmark(); prax.selectedSourceFile = sourceFile}
        .onTapGesture(count: 2) {prax.showPreview.toggle()}
        .contextMenu {SourceFileContextMenu(sourceFile: sourceFile)}
        
        
        
    }
}

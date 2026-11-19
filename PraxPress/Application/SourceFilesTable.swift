//
//  SourceFilesTable.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/11/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SourceFilesTable: View {
    init(_ fileGroupName: String) { self.fileGroupName = fileGroupName }
    let fileGroupName: String
    @Environment(PraxModel.self) private var prax
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @SceneStorage("SourceFileTableConfig") private var columnCustomization: TableColumnCustomization<SourceFile>
    @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
    @Query(sort: \SourceFile.addedDate) private var sourceFiles: [SourceFile]
    @State var sortOrder: [KeyPathComparator<SourceFile>] = [.init(\.addedDate, order: SortOrder.reverse)]
    @State private var path = NavigationPath()
    
    @State var selectedFiles = Set<SourceFile.ID>() { didSet { prax.selectedSourceFiles = selectedFiles } }
    
    var body: some View {
        let sourceFileGroup = sourceFileGroups.filter({$0.name == fileGroupName}).first
        if let sourceFiles = sourceFileGroup?.sourceFiles {
            
            @Bindable var prax = prax
            VStack {
                NavigationStack(path: $path) {
                    
                    Table(selection: $prax.selectedSourceFiles, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
                        TableColumn("Type", value: \.fileType) {sourceFile in Image(nsImage: NSWorkspace.shared.icon(forFile: sourceFile.url.path))
                        }.width(min: 30, ideal: 30, max: 30).customizationID("fileType")
                        
                        TableColumn("Filename", value: \.fileName) {sourceFile in
                            Text(sourceFile.fileName)
                                .foregroundStyle(sourceFile.status == SourceFileStatus.trashed ? Color.red : Color.buttonDefaultForeground)
                            
                        }.width(min: 100, ideal: 200, max: .infinity).customizationID("fileName")
                        
                        TableColumn("Pages", value: \.pageCount) { sourceFile in
                            Text("\(sourceFile.pageCount)")
                        }.width(min: 30, ideal: 40, max: 40).customizationID("pageCount")
                        
                        TableColumn("Size", value: \.fileSize) { sourceFile in
                            Text("\(formatFileSize(sourceFile.fileSize))")
                        }.width(min: 50, ideal: 60, max: 60).customizationID("fileSize")
                        
                        TableColumn("Added", value: \.addedDate) { sourceFile in
                            Text(formatSmartDate(sourceFile.addedDate))
                        }.width(min: 50, ideal: 60, max: 60).customizationID("addedDate")
                        
                        TableColumn("Modified", value: \.modificationDate) { sourceFile in
                            Text(formatSmartDate(sourceFile.modificationDate))
                        }.width(min: 50, ideal: 60, max: 60).customizationID("modificationDate")
                        
                        TableColumn("Created", value: \.creationDate) { sourceFile in
                            Text(formatSmartDate(sourceFile.creationDate))
                        }.width(min: 50, ideal: 60, max: 60).customizationID("creationDate")
                        
                        TableColumn("Favorite", value: \.exported, comparator: BoolComparator()) { sourceFile in
                            Toggle("Favorite", isOn: $prax.isLarge ).labelsHidden()
                        }.width(min: 30, ideal: 30, max: 100)
                    }
                    rows: {
                        ForEach(sourceFiles) { sourceFile in
                            TableRow(sourceFile)
                            .draggable(SourceFileTransfer(sourceFile: sourceFile))
                            .contextMenu {SourceFileContextMenu(sourceFile: sourceFile)}
                            
                        }
                        
                    }
                    .tableStyle(.bordered)
                    
                    
                    .contextMenu(forSelectionType: SourceFile.ID.self) { selectedIDs in }
                    primaryAction: { selectedIDs in guard
                        let id = selectedIDs.first  else { return  }
                        if id != prax.selectedSourceFileID { prax.selectedSourceFileID = id }
                        guard prax.selectedSourceFile != nil else {return}
                        prax.document.addPagesFromSourceFile(prax.selectedSourceFile!)
                    }
                }
            }
        }
        
    }
}

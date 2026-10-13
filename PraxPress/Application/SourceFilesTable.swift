//
//  SourceFilesTable.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/11/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers



private struct BoolComparator: SortComparator {
    typealias Compared = Bool
    
    func compare(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
        switch (lhs, rhs) {
        case (true, false):
            return order == .forward ? .orderedDescending : .orderedAscending
        case (false, true):
            return order == .forward ? .orderedAscending : .orderedDescending
        default: return .orderedSame
        }
    }
    
    var order: SortOrder = .forward
}



struct SourceFilesTable: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.modelContext) private var modelContext
    
    @SceneStorage("SourceFileTableConfig") private var columnCustomization: TableColumnCustomization<SourceFile>
    
    @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
    
    let fileGroupName: String
    init(_ fileGroupName: String) { self.fileGroupName = fileGroupName }
    
    @State var sortOrder: [KeyPathComparator<SourceFile>] = [.init(\.addedDate, order: SortOrder.reverse)]
    //   @State private var selection = Set<SourceFile.ID>()
    
    @State private var path = NavigationPath()
    
    
    var body: some View {
        let sourceFileGroup = sourceFileGroups.filter({$0.name == fileGroupName}).first
        if let sourceFiles = sourceFileGroup?.sourceFiles {
            
            
            @Bindable var prax = prax
            VStack {
                NavigationStack(path: $path) {
                    
                    Table(selection: $prax.selectedFiles, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
                        TableColumn("Type", value: \.fileType) {sourceFile in
                            Image(nsImage: NSWorkspace.shared.icon(forFile: sourceFile.url.path))
                        }.customizationID("fileType")
                        
                        TableColumn("Filename", value: \.fileName) {sourceFile in
                            Text(sourceFile.fileName)
                        }.customizationID("fileName")
                        
                        TableColumn("Pages", value: \.pageCount) { sourceFile in
                            Text("\(sourceFile.pageCount)")
                        }.customizationID("pageCount")
                        
                        TableColumn("Size", value: \.fileSize) { sourceFile in
                            Text("\(formatFileSize(sourceFile.fileSize))")
                        }
                        .customizationID("fileSize")
                        
                        TableColumn("Added", value: \.addedDate) { sourceFile in
                            Text(formatSmartDate(sourceFile.addedDate)) }
                        .customizationID("addedDate")
                        
                        TableColumn("Modified", value: \.modificationDate) { sourceFile in
                            Text(formatSmartDate(sourceFile.modificationDate))}
                        .customizationID("modificationDate")
                        
                        TableColumn("Created", value: \.creationDate) { sourceFile in
                            Text(formatSmartDate(sourceFile.creationDate)) }
                        .customizationID("creationDate")
                        
                        TableColumn("Favorite", value: \.exported, comparator: BoolComparator()) { sourceFile in
                            Toggle("Favorite", isOn: $prax.isLarge )
                            .labelsHidden() }
                    }
                    rows: {
                        ForEach(sourceFiles) { sourceFile in
                            TableRow(sourceFile) .draggable(SourceFileTransfer(sourceFile: sourceFile))
                            
                            
                                .contextMenu {SourceFileContextMenu(sourceFile: sourceFile)}
                            
                        }
                    }
                    
                    .contextMenu(forSelectionType: SourceFile.ID.self) { selectedIDs in
                        //                guard let id = selectedIDs.first,
                        //                     let sourceFile = sourceFiles.first(where: { $0.id == id }) else { return  }
                        
                    } primaryAction: { selectedIDs in
                        guard let id = selectedIDs.first,
                              let sourceFile = sourceFiles.first(where: { $0.id == id }) else { return  }
                        
                        // Action on double-click
                        if sourceFile == prax.selectedSourceFile  {
                            prax.showPreview.toggle() }
                        else {
                            prax.selectedSourceFile = sourceFile
                            prax.showPreview = true
                        }
                        
                        
                    }
                    .navigationDestination(for: SourceFile.self) { sourceFile in
                        Text("Details for \(sourceFile.fileName) - \(sourceFile.fileName)")
                            .font(.largeTitle)
                    }
                    .navigationTitle("SourceFiles")
                }
                
                
                Text("\(prax.selectedFiles.count)  of \(sourceFiles.count) Files Selected")
                    .font(.subheadline)
            }
        }
        
    }
}

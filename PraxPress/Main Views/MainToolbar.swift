//
//  MainToolbar.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/7/26.
//

import SwiftUI
import SwiftData
import PDFKit

struct MainToolbar: ToolbarContent {
    @Environment(PraxContext.self) private var praxContext
    @Environment(\.modelContext) private var modelContext
    @Environment(PraxModel.self) private var prax

    @SceneStorage("ContentView.showFilesPanel") var showFilesPanel: Bool = true
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            ControlGroup {
                Button {
                    showFilesPanel.toggle()
                } label: {
                    Label((showFilesPanel ? "Hide Files" : "Show Files"), systemImage: (showFilesPanel ? "rectangle.lefthalf.inset.fill.arrow.left" : "tray.and.arrow.down"))
                }
                if showFilesPanel {
                    
                    Button {
                        if prax.columnVisibility == .detailOnly {
                            NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                        }
                        prax.showingImporter = true
                    } label: {
                        Label("Add Files", systemImage: "folder.badge.plus")
                    }
                    
                    if !prax.selectedFiles.isEmpty {
                        Button {
                            deleteSelectedFilesFromDatabase()
                        } label: {
                            Label("Remove Files", systemImage: "folder.badge.minus")
                        }
                        .disabled(prax.selectedFiles.isEmpty)
                    }
                    
                }
                
            }
            Button {
                prax.columnVisibility = .detailOnly
            } label: {
                if prax.columnVisibility == .all {
                    Label("All", systemImage: "rectangle.split.3x1")
                }
                else if prax.columnVisibility == .doubleColumn {
                    Label("Double Column", systemImage: "rectangle.split.2x1")
                }
                else {
                    Label("Detail Only", systemImage: "rectangle")
                    
                }
            }
            Button {
                prax.columnVisibility = .doubleColumn
            } label: {
                if prax.columnVisibility == .all {
                    Label("All", systemImage: "rectangle.split.3x1")
                }
                else if prax.columnVisibility == .doubleColumn {
                    Label("Double Column", systemImage: "rectangle.split.2x1")
                }
                else {
                    Label("Detail Only", systemImage: "rectangle")
                    
                }
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Spacer()
            HStack {
                Spacer(minLength: 5)
                Text("Drag as...   ")
                Spacer(minLength: 5)
                Text(prax.exportFilenamePrefix)
                TextField("Filename", text: Binding<String>(
                    get: { prax.exportFilenameBody },
                    set: { newValue in
                        var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let dotRange = newName.range(of: ".") {
                            newName = String(newName[..<dotRange.lowerBound])
                        }
                        prax.exportFilenameBody = newName
                    })
                )
                .frame(minWidth: 20, idealWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                .textFieldStyle(SquareBorderTextFieldStyle())
                .disabled(prax.exportFolderURL == nil)
                .foregroundStyle(.cyan)
                .backgroundStyle(.yellow)

                Text(prax.exportFilenameSuffix)
                Spacer(minLength: 5)
                Image(systemName: "arrow.right.doc.on.clipboard")
                Spacer(minLength: 5)
                Text(".\(prax.exportFilenameExtension)")
                Spacer(minLength: 15)
            }
            .draggable {
                if let data = prax.mergedPDFDocument.dataRepresentation() {
                    return MergedPDFTransfer(data: data, filename: (prax.exportFilename))
                } else { return nil }
            }
            Spacer()
        }

        ToolbarItemGroup(placement: .primaryAction) {


            Button("Save As …", systemImage: "arrow.down.document") {
                prax.showSavePanel.toggle()
            }

            Button {
                prax.showingMergedDocumentInspector.toggle()
            } label: {
                Label((prax.showingMergedDocumentInspector ? "Hide Merged" : "Show Merged"), systemImage: (prax.showingMergedDocumentInspector ? "minus.magnifyingglass" : "plus.magnifyingglass"))
            }
            Button {
                prax.showingPDFPageItemInspector.toggle()
            } label: {
                Label((prax.showingPDFPageItemInspector ? "Hide PDFPageItem" : "Show PDFPageItem"), systemImage: (prax.showingPDFPageItemInspector ? "minus.magnifyingglass" : "plus.magnifyingglass"))
            }

            Button {
                prax.isLarge.toggle()
            } label: {
                Label((prax.isLarge ? "Status Small" : "Status Large"), systemImage: (prax.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                prax.isShowingInspector.toggle()
            } label: {
                Label((prax.isShowingInspector ? "Hide Inspector" : "Show Inspector"), systemImage: (prax.isShowingInspector ? "info.square.fill" : "info.square"))
            }
        }
    }
    
    func deleteSelectedFilesFromDatabase() {
        prax.selectedFiles.forEach({ id in
            let pdfFile = prax.pdfFiles.first(where: { $0.id == id })!
            modelContext.delete(pdfFile)
        })
        prax.selectedFiles.removeAll()
    }
    

}

//
//  EditingDocumentToolbar.swift
//  PraxPress
//
//  Created by Elmer Cat on 4/9/26.
//

import SwiftUI
import PDFKit
import TipKit
import UniformTypeIdentifiers

struct DocumentEditingToolbar: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    let praxTheme = PraxTheme(.erika)
    
    @State var showDataFields = false
    @State var showSettings = false
    @State var showDelete = false
    @State private var hoveredButton: Int? = nil
    @State private var showFilenamePrefixPopover = false
    
    private func title(for mode: PDFDisplayMode) -> String {
        switch mode {
        case .singlePage: return "Single"
        case .singlePageContinuous: return "Continuous"
        case .twoUp: return "Two Up"
        case .twoUpContinuous: return "Two Up Cont."
        @unknown default: return "Unknown"
        }
    }
    
    let filenameStyle = URL.FormatStyle(scheme: .never,
                                        user: .never,
                                        password: .never,
                                        host: .always,
                                        port: .never,
                                        path: .always,
                                        query: .never,
                                        fragment: .never)
 
    var body: some View {
        @Bindable var prax = praxModel
        @Bindable var document = document
        
        let _ = Self._printChanges()
        
        GroupBox {
                
                HStack {
                
                    Button {
                        showDelete = !showDelete
                    }label: {
                        Image(systemName: document.mergedPages.isEmpty ? "rectangle.dashed" : "rectangle.stack.slash")
                    }
                    .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 40, isDisabled: document.mergedPages.isEmpty))
                    .onHover { hovering in hoveredButton = hovering ? 40 : nil }
                    .disabled(document.mergedPages.isEmpty)
                    .popover(isPresented: $showDelete, arrowEdge: .leading) {
                        DeletePopover() }
  
                    
                    
                    Spacer()
                    
                   
                    if let pageItem = prax.selectedPageItem {
                     //   Text(pageItem.name)
                        Group {
                            Button { showFilenamePrefixPopover = !showFilenamePrefixPopover  }
                            label: {
                                if document.exportFilenamePrefix == "" {
                                    Text("prefix...").italic().foregroundStyle(.gray)
                                }
                                else {
                                    Text(document.exportFilenamePrefix).bold()
                                }
                            }
                            .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 42))
                            .onHover { hovering in hoveredButton = hovering ? 42 : nil }
                            .popover(isPresented: $showFilenamePrefixPopover, arrowEdge: .leading) {
                                FilenamePrefixPopover() }
                            
                            TextField("Filename", text: Binding<String>(
                                get: { document.exportFilenameBody },
                                set: { newValue in
                                    var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    // Ensure we don't accidentally include a dot/extension typed by the user
                                    if let dotRange = newName.range(of: ".") {
                                        newName = String(newName[..<dotRange.lowerBound])}
                                    document.exportFilenameBody = newName
                                })
                                      
                            )
                            //   .frame(minWidth: 10, idealWidth: 20, alignment: .init(horizontal: .trailing, vertical: .center))
                            
                            .frame(width: 200)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                           // .disabled(document.exportFolderURL == nil)
                            
                            
                            
                            Text(".pdf")
                            Button("Drag", systemImage: "arrow.right.doc.on.clipboard") {
                                
                            
                            }
                            .draggable({ () -> MergedPDFTransfer? in
                                guard let data = document.mergedPDFDocument.dataRepresentation(options: [PDFDocumentWriteOption.burnInAnnotationsOption: (prax.annotationSaveMode == .burnIn)]) else { return nil }
                                return MergedPDFTransfer(data: data, filename: document.exportFilename)
                            }()!, preview: {
                                PraxDragPreview()
                            })
                            
                            if !pageItem.dataFields.isEmpty {
                                
                                Spacer()
                                
                                Button { showDataFields = !showDataFields }label: {
                                    GroupBox {
                                        HStack {
                                            Image(systemName: showDataFields ? "list.bullet.rectangle.fill": "list.bullet.rectangle")
                                            Text("Data Fields")
                                        }
                                    }
                                }
                                
                                .buttonStyle(SwitchButtonStyle(isOn: showDataFields, isHovering: hoveredButton == 417))
                                .controlSize(.extraLarge)
                                .onHover { hovering in hoveredButton = hovering ? 417 : nil }
                                .inspectorPanel(isPresented: $showDataFields) { DataFieldsEditor().environment(prax) }
             
                                PraxSegmentedControl(selection: $prax.annotationSaveMode, colorProvider: { $0.color }, iconProvider: { $0.icon })
                                
                                Spacer()
                                
                            }
                            
                            Spacer(minLength: 15)

                            Button("Save", systemImage: "square.and.arrow.down") {
                                var isStale = false
                                if let bookmark = document.exportFileURLBookmark, let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) {
                                    let needsStop = url.startAccessingSecurityScopedResource()
                                    defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
                                
                                //    document.mergedPDFDocument.write(to: url)
                                    document.mergedPDFDocument.write(to: url, withOptions: [PDFDocumentWriteOption.burnInAnnotationsOption: (prax.annotationSaveMode == .burnIn)])
                           
                                }
                                else {
                                    prax.showSavePanel.toggle()

                                }
                                
                            }
                            Button("Save As…", systemImage: "square.and.arrow.down.on.square") {
                                prax.showSavePanel.toggle()
                            }
                        }
                        
                    }
                    else {
                        Text("Select a Page Item to Edit").font(Font.custom("BrushScriptMT", size: 20))
                    }
                 
                    Spacer()
                }
            
                .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
                .padding(0)
                
       
            
            

            
        }
        
        
        .onDrop(of: [.fileURL], delegate: PraxDropDelegate(document, prax))

        
  //     .background(PraxGradient(2))
  //      .background(prax.dropTargeted ? Color(red: 0.4, green: 0.4, blue: 0.8, opacity: 0.3) : Color.orange)
    //    .foregroundStyle(Color.white)
        
        
    }
    
    private var dragPreviewView: some View {
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
                Text("\(document.exportFilename).pdf")
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
            }
        }
        
    }
    

}

struct DocumentEditingFooter: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    let filenameStyle = URL.FormatStyle(scheme: .never,
                                        user: .never,
                                        password: .never,
                                        host: .always,
                                        port: .never,
                                        path: .always,
                                        query: .never,
                                        fragment: .never)
    var body: some View {
        @Bindable var prax = praxModel
        HStack {
            switch (prax.selectedFiles.count) {
            case 0:
                Text("No files selected")
            case 1:
                Text("Source file: \(document.exportFilenameBody)")
            default:
                Text("\(prax.selectedFiles.count) Source files selected")
            }
            Spacer()
   //         Text(String(format: "Window size: \(prax.windowSize.width) x \(prax.windowSize.height) -- -- SplitView width: \(prax.splitViewFrameWidth) -  divZero@:  \(prax.dividerZeroPos) -  divOne@:   \(prax.dividerOnePos)"))
        }
        .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
        .padding(8)
    }
}



struct EditingDocumentToolbar: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    
    @FocusState private var focusedField: String?
    @FocusState private var amountFocused: Bool
    @State private var hoveredButton: Int? = nil
    @State private var showFilenamePrefixPopover = false
//    @State private var guideXLeft = 0.0
//    @State private var guideXRight = 0.0
    
    func currentPageIndex() -> Int {
        if let pdfDocument = prax.editingDocumentPDFView.document {
            if let pdfPage = prax.editingDocumentPDFView.currentPage {
                return pdfDocument.index(for: pdfPage)
            }
        }
        return 0
    }
    
    var body: some View { GeometryReader { proxy in
        @Bindable var prax = prax
        
        if let pageItem = prax.selectedPageItem {
            
            let undoManager = prax.undoManager
            let _ = Self._printChanges()

            let decimals = Set("0123456789.-+")
            
            GroupBox {
                
                    
                    VStack {
                        HStack {
                            
                            
                            GroupBox {
                                HStack {
                                        GroupBox() {
                                            VStack {
                                                Text("\(prax.editingDocumentPDFView.document?.pageCount ?? 0) Pages").font(.system(size: 8))
                                                
                                                HStack {
                                                    Text(String("\(currentPageIndex() + 1)")).monospaced()
                                                    VStack(spacing: 0) {
                                                        Button { prax.editingDocumentPDFView.goToPreviousPage(self) }
                                                        label: { Image(systemName: "arrowtriangle.up")  }
                                                            .disabled(!prax.editingDocumentPDFView.canGoToPreviousPage)
                                                            .buttonStyle(StackedButtonStyle(isHovering: hoveredButton == 11, isFocused: false))
                                                            .onHover { hovering in hoveredButton = hovering ? 11 : nil }
                                                        
                                                        Button { prax.editingDocumentPDFView.goToNextPage(self) }
                                                        label: {  Image(systemName: "arrowtriangle.down")}
                                                            .disabled(!prax.editingDocumentPDFView.canGoToNextPage)
                                                            .buttonStyle(StackedButtonStyle(isHovering: hoveredButton == 12, isFocused: false))
                                                            .onHover { hovering in  hoveredButton = hovering ? 12 : nil }
                                                    }
                                                    
                                                }
                                                 
                                                
                                            }
                                            
                                            
                                            
                                        }
                                        .background(Color.clear, in: .containerRelative)
                                        .overlay( RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1) )
                                        .padding(2)
                                    Divider().foregroundStyle(.white).background(.white)
 
                                    Button {undoManager.undo() }
                                    label: {
                                        Text(String("\(undoManager.undoCount)")) // .font(.system(size: 8))
                                        Image(systemName: undoManager.undoCount > 0 ? "arrow.uturn.backward.circle.fill" : "arrow.uturn.backward.circle" )                                    }
                                    .disabled(undoManager.undoCount < 1)
                                    .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 274))
                                    .onHover { hovering in hoveredButton = hovering ? 274 : nil }
                                    
                                    //         Text(String("\(undoManager.undoCount)"))
                                    
                                    //               Text("\(pageItem.name)  Redo").font(.system(size: 8))
                                    Button {undoManager.redo() }
                                    label: { if undoManager.redoCount > 0 {
                                        Image(systemName: "arrow.uturn.forward.circle.fill") } else {
                                            Image(systemName: "arrow.uturn.forward.circle") }
                                        Text(String("\(undoManager.redoCount)")).font(.system(size: 8)) }
                                    .disabled(undoManager.redoCount < 1)
                                    .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 276))
                                    .onHover { hovering in hoveredButton = hovering ? 276 : nil }
                                    
                                    Spacer()
                                    
                                    Divider().foregroundStyle(.white).background(.white)
                                    
                                    PageItemTrimsView()
                                    

                                    
                                }
                            }
                            
                            
                            
                            
                        }
                        if pageItem.mergedPage.hasDataFields {
 
                            HStack {
                               
                                Text("Document")
                                PasteButton(payloadType: String.self) { strings in
                                      if let firstString = strings.first {
                                          pageItem.dataFields["DocumentNumber"] = .string(firstString.filter(\.isNumber))
                                      }
                                  }
                                  .buttonBorderShape(.capsule)
                                TextField("Document", text: Binding<String>(
                                    get: { pageItem.dataFields["DocumentNumber"]?.stringValue ?? "" },
                                    set: { newValue in
                                        pageItem.dataFields["DocumentNumber"] = .string(newValue.filter(\.isNumber))
                                    }
                                ) )
                                .focused($focusedField, equals: "DocumentNumber")
                                .frame(minWidth: 50, maxWidth: 100)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Text("Amount")
                                TextField("Amount", text: Binding<String>(
                                    get: { pageItem.dataFields["Amount"]?.stringValue ?? "" },
                                    set: { newValue in
                                        pageItem.dataFields["Amount"] = .string(newValue.filter{decimals.contains($0)} )
                                        if "Amount" == "Amount" {
                                            prax.document.exportFilenameBody = newValue.filter(\.isNumber)
                                        }
                                    }
                                ) )
                            //    .focused($focusedField, equals: "Amount")
                                .focused($amountFocused)
                                            .onChange(of: amountFocused) { oldValue, newValue in
                                                if newValue {
                                                    // Set selection to the entire range of the text
                                            //        .selection = .init(pageItem.dataFields["Amount"] .startIndex..<pageItem.dataFields["Amount"] .endIndex)
                                                }
                                            }
                                .frame(minWidth: 50, maxWidth: 100)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                }

                            }
 
                        }

                        
                    }.padding(0)
                    
                
                
                
           
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerSize: CGSize(width: 5, height: 5), style: .continuous).fill(PraxGradient(3)))
        }
        else { EmptyView() }
    } }
    
    
 
}


struct EditingDocumentFooter: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let praxTheme = PraxTheme(.erika)
    
    @State private var hoveredButton: Int? = nil
    
   
    var body: some View {
        @Bindable var prax = praxModel
        
        if let pageItem = prax.selectedPageItem {
            let pageCount = pageItem.mergedPage.pageItems.count
            let curentPageIndex = 764 //pageItem.mergedPage.pageItems.firstIndex(of: pageItem)!

            
            let mergedSizeText = {
                let wIn = pageItem.trimmedPageSize().width / 72.0
                let hIn = pageItem.trimmedPageSize().height / 72.0
                return String(format: "%.1f\" × %.1f\"", wIn, hIn)
            }
            
            HStack {

                Button("", systemImage: "arrow.up.and.down.circle", action: {
                    EditingPDFDocumentView.scalePDFViewToFit(pdfView: prax.editingDocumentPDFView)
                })
                .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 0, isFocused: false))
                .onHover { hovering in
                    hoveredButton = hovering ? 0 : nil
                }

                Button("", systemImage: "minus.circle", action: {
                    prax.editingDocumentPDFView.zoomOut(self)
                })                .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 2, isFocused: false))
                    .onHover { hovering in
                        hoveredButton = hovering ? 2 : nil
                    }

                Button("", systemImage: "plus.circle", action: {
                    prax.editingDocumentPDFView.zoomIn(self)
                })
                .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 1, isFocused: false))
                .onHover { hovering in
                    hoveredButton = hovering ? 1 : nil
                }

                Button("", systemImage: "arrow.left.and.right.circle", action: {
                    prax.editingDocumentPDFView.autoScales = true
                })                .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 3, isFocused: false))
                    .onHover { hovering in
                        hoveredButton = hovering ? 3 : nil
                    }
                
                Spacer()
                Text((prax.selectedPageItem?.name  ?? "No Current Page") + mergedSizeText() )
                Spacer()
                GroupBox {
                    HStack {
                        Button("", systemImage: "arrowshape.left.circle", action: {
                            prax.editingDocumentPDFView.goToPreviousPage(self)
                        })
                        .disabled(!prax.editingDocumentPDFView.canGoToPreviousPage)
                        .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 11, isFocused: false))
                        .onHover { hovering in
                            hoveredButton = hovering ? 11 : nil
                        }
                        
                        Text(String("Page \(curentPageIndex + 1) of \(pageCount)"))
                            .background {
                                Capsule()
                                    .foregroundStyle(Color.blue.gradient)
                            }
                        
                        Button("", systemImage: "arrowshape.right.circle", action: {
                            prax.editingDocumentPDFView.goToNextPage(self)
                        })
                        .disabled(!prax.editingDocumentPDFView.canGoToNextPage)
                        .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 12, isFocused: false))
                        .onHover { hovering in
                            hoveredButton = hovering ? 12 : nil
                        }
                    }
              }
            }
            .background(PraxGradient(1))
        }
        else { EmptyView() }
    }
}

#Preview {
    
   
    EditingDocumentToolbar()
 //       MergedDocumentView()
//    MergedDocumentFooter()
   
}


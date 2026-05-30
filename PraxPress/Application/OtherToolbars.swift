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
                            
                            Button { }
                            label: {
                                HStack{
                                    GroupBox {
                                        HStack {
                                            Image(systemName: "arrow.right.doc.on.clipboard")
                                            if hoveredButton == 150 {
                                                
                                                Text("Drag")
                                                Text("\(document.exportFilename).pdf")
                                                if prax.selectedPageItem?.mergedPage.dataFieldPage != nil {
                                                    PraxSegmentedControl(selection: $prax.annotationSaveMode, colorProvider: { $0.color }, iconProvider: { $0.icon })
                                                }
                                            }
                                            }
                                        }
                                    }
                                    
                                    
                                }
                                
                                .buttonStyle(DragButtonStyle(isHovering: hoveredButton == 150))
                                .onHover { hovering in hoveredButton = hovering ? 150 : nil }
                                
                                .draggable({ () -> MergedPDFTransfer? in
                                    guard let data = document.mergedPDFDocument.dataRepresentation(options: [PDFDocumentWriteOption.burnInAnnotationsOption: (prax.annotationSaveMode == .burnIn)]) else { return nil }
                                    return MergedPDFTransfer(data: data, filename: document.exportFilename)
                                }()!, preview: {
                                    PraxDragPreview()
                                })
                            

                        
                            
                            if pageItem.mergedPage.dataFieldPage != nil {
                                
                                Spacer()
                                
                                Button { prax.showDataFields = !prax.showDataFields }label: {
                                    GroupBox {
                                        HStack {
                                            Image(systemName: prax.showDataFields ? "list.bullet.rectangle.fill": "list.bullet.rectangle")
                                            Text("Data Fields")
                                        }
                                    }
                                }
                                
                                
                                .buttonStyle(SwitchButtonStyle(isOn: prax.showDataFields, isHovering: hoveredButton == 417))
                                .controlSize(.extraLarge)
                                .onHover { hovering in hoveredButton = hovering ? 417 : nil }
                                
             
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
    @State private var showDatePopover = false
    @State private var showDocumentNumberPopover = false
    @State private var showAmountPopover = false
    @State private var showDescriptionPopover = false
    @State private var showVendorAccountsPopover = false
    
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
                    if let dataFieldPage = pageItem.mergedPage.dataFieldPage {
                        
                        HStack (spacing: 0) {
                            
                            GroupBox {
                                Button { showDatePopover = true}
                                label: { Text("\(dataFieldPage.dataFields["Date"]?.stringValue ?? "" )").font(.system(size: 10)).padding(0)
                                }
                                    .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 410, isDisabled: document.mergedPages.isEmpty))
                                    .onHover { hovering in hoveredButton = hovering ? 410 : nil }
                                    .disabled(showDatePopover == true)
                                    .popover(isPresented: $showDatePopover, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                                        DatePopover() }
                            }
                            .padding(0)
                            .background(PraxGradient(2))
                            .border(.blue, width: 1)
                            
                            GroupBox {
                                HStack(spacing: 0) {
                                    Button { if let string = NSPasteboard.general.string(forType: .string){
                                            dataFieldPage.dataFields["DocumentNumber"] = .string(string.filter(\.isNumber)) } }
                                     label: {
                                         Image(systemName: "arrow.right.page.on.clipboard").padding(0)
                                    }
                                     .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 422))
                                     .onHover { hovering in hoveredButton = hovering ? 422: nil }

                               //     .controlSize(.mini)
                                    Divider()

                                    Button { showDocumentNumberPopover = true }
                                    label: { Text("Doc# \(dataFieldPage.dataFields["DocumentNumber"]?.stringValue ?? "" )").font(.system(size: 10))}
                                        .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 421, isDisabled: document.mergedPages.isEmpty))
                                        .onHover { hovering in hoveredButton = hovering ? 421 : nil }
                                        .disabled (showDocumentNumberPopover == true )
                                        .popover(isPresented: $showDocumentNumberPopover, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                                            DocumentNumberPopover() }
                                        .padding(.trailing, 5)
                                  //      .frame(minWidth: 130, idealWidth: 130, maxWidth: 130, minHeight: 30, idealHeight: 30, maxHeight: 30, alignment: .trailing)
                                        
                                    

                                }
                          //      .frame(minWidth: 130, idealWidth: 130, maxWidth: 130, minHeight: 30, idealHeight: 30, maxHeight: 30, alignment: .trailing)
                                .padding(.horizontal, 4)
                                .background(PraxGradient(2))
                                .border(.blue, width: 1)

                                
                            }
               
                            
                            GroupBox {
                                Button { showVendorAccountsPopover = true}
                                label: { Text("Vendor/Accounts").font(.system(size: 10)).padding(0)
                                }
                                    .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 460, isDisabled: document.mergedPages.isEmpty))
                                    .onHover { hovering in hoveredButton = hovering ? 460 : nil }
                                    .disabled(showDatePopover == true)
                                    .popover(isPresented: $showVendorAccountsPopover, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                                        VendorAccountsPopover() }
                            }
                            .padding(0)
                            .background(PraxGradient(2))
                            .border(.blue, width: 1)
                            
                            
                            
                            GroupBox {
                                HStack(spacing: 0) {


                                    Button { showDescriptionPopover = true }
                                    label: {
                                        Image(systemName: "pencil.and.list.clipboard").padding(0)
                                        Text("Description").font(.system(size: 8, weight: .ultraLight))
                                    }
                                        .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 451, isDisabled: document.mergedPages.isEmpty))
                                        .onHover { hovering in hoveredButton = hovering ? 451 : nil }
                                        .disabled (showDescriptionPopover == true )
                                        .popover(isPresented: $showDescriptionPopover, attachmentAnchor: .point(.bottomLeading), arrowEdge: .bottom) {
                                            DescriptionPopover() }
                                        .padding(0)

                                    Button {
                                        let pasteboard = NSPasteboard.general
                                            pasteboard.clearContents()
                                            pasteboard.setString(dataFieldPage.dataFields["Description"]?.stringValue ?? "" , forType: .string)
                                    }
                                     label: {
                                         Image(systemName: "arrow.up.page.on.clipboard").padding(0)
                                    }
                                     .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 452))
                                     .onHover { hovering in hoveredButton = hovering ? 452: nil }

                               //     .controlSize(.mini)
                                    .padding(0)
                                    
                                    

                                }
                                .background(PraxGradient(2))
                                .border(.blue, width: 1)

                                
                            }
                            
                            
                            GroupBox {
                                Button { showAmountPopover = true }
                                label: { Text("Amount: $\(dataFieldPage.dataFields["Amount"]?.stringValue ?? "" )").font(.system(size: 10)).padding(0)}
                                    .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 420, isDisabled: document.mergedPages.isEmpty))
                                    .onHover { hovering in hoveredButton = hovering ? 420 : nil }
                                    .disabled (showAmountPopover == true )
                                    .popover(isPresented: $showAmountPopover, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                                        AmountPopover() }
                            }
                            .padding(0)
                            .background(PraxGradient(2))
                            .border(.blue, width: 1)
                            
                            
                        }
                        .padding(0)
                        
                        
                        
                        
                    }
                }
            }
            .padding(0)
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
            let curentPageIndex = pageItem.mergedPage.pageItems.firstIndex(of: pageItem) ?? -1

            
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


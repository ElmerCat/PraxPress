//
//  MergedPagesView.swift
//  PraxPress
//
//  Created by Elmer Cat on 9/5/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PDFKit

private let DEBUG_LOGS = true



struct MergedPagesView: View {
    
    //  @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var dragStart: CGPoint? = nil
    @State private var dragRect: CGRect? = nil
    @State private var dragBaseSelection: Set<UUID> = []
    @State private var dragAnchor: UUID? = nil
    @State private var dropTargeted: Bool = false
    
    var body: some View {
        
        @Bindable var prax = prax
        
        VStack{
            Text("Merged Pages")
            
            MergedPagesList()
                .background(
                    DragSelectionOverlay(
                        dragRect: $dragRect,
                        rowFrames: rowFrames,
                        allIDs: prax.allItemIDs,
                        idToUUID: { $0 },
                        onSetSelection: { ids in
                            let combined = dragBaseSelection.union(ids)
                            prax.selectionModel.setSelected(combined, keepAnchor: dragAnchor)
                            prax.selectedPages = combined }
                    ) )
                .frame(minHeight: 200, maxHeight: .infinity)
               // .background(.mergedPDFViewBackground)
                .background(dropTargeted ? Color.yellow : Color.clear)
                .coordinateSpace(name: "ScrollSpace")
                .onPreferenceChange(RowFramePreferenceKey.self) { frames in rowFrames = frames }
                .gesture(dragSelectionGesture(selection: prax.selectionModel))
            
            
            MergedPagesFooter()
        }
        .background(dropTargeted ? PraxGradient(4) : PraxGradient(0))
        
        .dropDestination(
            for: SourceFileTransfer.self,
            action: {
                items, location in
                for item in items {
                    prax.document.addPagesFromSourceFilePayload(item.payload, at: IndexPath(item: 0, section: -1) )
                }
                return true},
            isTargeted: { targeted in dropTargeted = targeted })
       
        
        .task { DispatchQueue.main.async { print ("MergedPagesView .task Anita") } }
        .onAppear() { print ("MergedPagesView .onAppear() Geraldine") }
        .onDisappear() { print ("MergedPagesView .onDisappear() Elsie") }
        
    }
    
    private func dragSelectionGesture(selection: SelectionModel<UUID>) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = value.startLocation
                    dragBaseSelection = selection.selected
                    dragAnchor = selection.anchor ?? selection.lastClicked
                }
                guard let start = dragStart else { return }
                dragRect = rect(from: start, to: value.location)
            }
            .onEnded { _ in
                dragStart = nil
                dragRect = nil
                dragBaseSelection = []
                dragAnchor = nil
                prax.selectedPages = selection.selected
            }
    }
    
    private func rect(from a: CGPoint, to b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }
    
    struct MergedPagesList: View {
        //  @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
        //  @Environment(PersistenceController.self) private var persistence
        
        @Environment(PraxModel.self) private var praxModel
        
        @State private var dropTargeted: Bool = false
        
        var body: some View {
            //   @Bindable var document = document
            @Bindable var prax = praxModel
            
            
            ScrollView {
                
                Grid(verticalSpacing: 20) {
                    ForEach(prax.document.mergedPages) { mergedPage in
                        MergedPageView(mergedPage: mergedPage)
                            .reportRowFrame(id: mergedPage.id)
                        
                    }
                    
                }
                
            }
            .padding(.top, 20)
            
            
            
            .onChange(of: prax.selectedMergedPages) { print(".onChange(of: prax.selectedMergedPages) {")  }
        }
    }
    
}

struct MergedPageView: View {
    @Environment(PraxModel.self) private var prax
    let mergedPage: MergedPage
    @State private var dropTargeted: Bool = false
    @State private var viewSize: CGSize = .zero
    @State private var hovering: Bool = false
    @State private var dropOperation: DropOperation = .cancel
    
    var body: some View {
        @Bindable var prax = prax
        GroupBox {
            VStack {
                SectionHeaderView(mergedPage: mergedPage, isSelected: prax.selectedPages.contains(mergedPage.id), highlightState: .none)

 
                ForEach(mergedPage.pageItems) { pageItem in
                    PageItemView(pageItem: pageItem, isSelected: prax.selectedPages.contains(pageItem.id), highlightState: .none)
                    //   .frame(height: prax.pageItemHeight)
                        .aspectRatio(1, contentMode: .fit)
                        .reportRowFrame(id: pageItem.id)
                        .onTapGesture {
                            prax.selectionModel.clearAndSelect(pageItem.id)
                            prax.selectedPageItem = pageItem
                            prax.selectedPages = prax.selectionModel.selected
                        }
                        .highPriorityGesture(
                            TapGesture()
                                .modifiers(.command)
                                .onEnded {
                                    prax.selectionModel.toggle(pageItem.id)
                                    prax.selectedPages = prax.selectionModel.selected
                                }
                        )
                        .highPriorityGesture(
                            TapGesture()
                                .modifiers(.shift)
                                .onEnded {
                                    prax.selectionModel.selectRange(allIDs: prax.allItemIDs, to: pageItem.id, additive: false)
                                    prax.selectedPages = prax.selectionModel.selected
                                }
                        )
                        .contentShape(Rectangle())
                        .draggable(containerItemID: pageItem.id)
                    
                }
                Divider()
            }
            .dragContainer(for: PageItem.self, itemID: \.id) { itemIDs in
                //       print("Drag: \(itemIDs)")
                return mergedPage.pageItems.filter { itemIDs.contains($0.id) }
            }
            .dragPreviewsFormation(.list)
            .dragContainerSelection(prax.selectedPages.sorted())
            
            
            .dropDestination(
                for: SourceFileTransfer.self, action: {
                    droppedItems, location in
                    //          print("MergedPageView.dropDestination(for: SourceFileTransfer - Height: \(viewSize.height) Location: \(location.y)")
                    guard let section = prax.document.mergedPages.firstIndex(of: mergedPage) else {return false}
                    let currentItemCount = mergedPage.pageItems.count
                    let itemSpace = viewSize.height / CGFloat(currentItemCount)
                    let item = Int(location.y / itemSpace)
                    for droppedItem in droppedItems {
                        prax.document.addPagesFromSourceFilePayload(droppedItem.payload, at: IndexPath(item: item, section: section), toMergedPage: mergedPage) }
                    return true },
                isTargeted: { targeted in dropTargeted = targeted })
            .dropConfiguration { dropSession in dropOperation = .copy
                return DropConfiguration(operation: dropOperation) }
            

            
        }
        .onGeometryChange(for: CGSize.self) { proxy in proxy.size } action: { newSize in viewSize = newSize }
        .onHover { isHovering in hovering = isHovering }
        
        .background(dropTargeted ? Color.green : Color.clear)
        .dropDestination(
            for: PageItem.self,
            action: {items, location in
                var itemIDs: Array<UUID> = []
                for item in items {
                    itemIDs.append(item.id)
                }
                if let section = prax.document.section(forMergedPage: mergedPage) {
                    let indexPath = IndexPath(item: 0, section: section)
                    if dropOperation == .move {
                        prax.document.movePageItems(itemIDs: itemIDs, to: indexPath)
                    }
                    else if dropOperation == .copy {
                        prax.document.copyPageItems(itemIDs: itemIDs, to: indexPath)
                    }
                }
                return true },
            isTargeted: { targeted in dropTargeted = targeted })
        
        .dropConfiguration { dropSession in dropOperation = prax.optionKeyPressed ? .copy : .move
            return DropConfiguration(operation: dropOperation) }
        
        
    }
}



struct SectionHeaderView: View {
    //  @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    
    
    @State var showSettings = false
    
    let mergedPage: MergedPage?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    var body: some View {
        if mergedPage != nil {
            @Bindable var section = mergedPage!
            @Bindable var prax = praxModel
            let clickGesture = TapGesture()
                .onEnded { value in
                    print("View tapped! - \(section.title) - PraxModel.shared.optionKeyPressed: \(prax.optionKeyPressed)")
                    clickedSectionHeader()
                }
            
            GroupBox {
                HStack {
                    Button {
                        showSettings = !showSettings
                    }
                    label: { Image(systemName: "gear")}
                        .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 2))
                        .onHover { hovering in
                            prax.hoveredButton = hovering ? 2 : nil
                        }
                    
                        .popover(isPresented: $showSettings, arrowEdge: .leading) {
                            SectionHeaderPopover(mergedPage: mergedPage!)
                                .presentationDetents(
                                    [.height(120), .medium, .large])
                                .presentationBackgroundInteraction(
                                    .enabled(upThrough: .height(120)))
                                .presentationSizing(.form)
                        }
                    
                    Spacer()
                    Text("\(section.title)")
                    // .font(.system(.subheadline))
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.horizontal, 5)
                        .draggable({ () -> MergedPDFTransfer? in
                            guard let data = prax.document.mergedPDFDocument.dataRepresentation() else { return nil }
                            return MergedPDFTransfer(data: data, filename: prax.document.exportFilename)
                        }()!, preview: {
                            PraxDragPreview()
                        })
                    Spacer()
                }
                .background(self.isSelected ?  Color.blue.opacity(0.7) : Color.black.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.cyan, lineWidth: 2))
                .gesture(clickGesture)
                
            }
            .padding(0)
        }
        else {
            EmptyView()
        }
    }
    
    func clickedSectionHeader(_ modifiers: EventModifiers = [] ) {
        print ("Julie d'Prax - clickedSectionHeader")
        if modifiers.contains(.shift) {
            print("Shift + Click detected")  }
        else if modifiers.contains(.command) {
            print("Command + Click detected")  }
        else if modifiers.contains(.control) {
            print("Control + Click detected")  }
        else {
            print("Plain Click detected")
            //        praxModel.currentEditingMergedPage = mergedPage
        }
    }
    
    struct SectionHeaderPopover: View {
        let mergedPage: MergedPage
        @Environment(\.dismiss) private var dismiss
        //  @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
        @Environment(PraxModel.self) private var prax
        let praxTheme = PraxTheme()
        let deleteTheme = PraxTheme()
        
        @State private var imageAngle = 0.0
        
        var theTip = PageItemTip()
        
        var body: some View {
            
            VStack {
                GroupBox {
                    HStack {
                        Image("PraxPress").resizable().aspectRatio(contentMode: .fit).frame(width: 40)
                            .padding(3)
                            .rotationEffect(Angle(degrees: imageAngle))
                            .onAppear {
                                withAnimation {
                                    imageAngle -= 3000
                                }
                                
                            }
                            .onDisappear {
                                withAnimation {
                                    imageAngle = 0
                                }
                            }
                        
                        if prax.document.mergedPages.count > 1 {
                            Text("\(prax.document.mergedPages.count) Merged Pages from \(prax.document.totalPageItems) Page Items")
                        }
                        else {
                            Text("Merged Page")
                        }
                    }
                    
                }
                
                Divider()
                
                GroupBox {
                    Text("\(mergedPage.title).pdf")
                    if mergedPage.pageItems.count < 2 {
                        Text("Just Trimming This Page")
                    }
                    else if mergedPage.skippedPages < 1 {
                        Text("Merging \(mergedPage.pageItems.count) Pages")
                    }
                    else {
                        Text("Skipping \(mergedPage.skippedPages) of \(mergedPage.pageItems.count) Pages")
                    }
                    
                    Grid(alignment: .trailing) {
                        
                        Divider()
                        
                        GridRow {
                            if mergedPage.pageItems.count == 1 {
                                Text("Include This Page")
                            }
                            else if mergedPage.pageItems.count == 2 {
                                Text("Include Both Pages")
                            }
                            else {
                                Text("Include All \(mergedPage.pageItems.count) Pages")
                            }
                            
                            Button {
                                mergedPage.includeAllPages()
                                dismiss() }
                            label: {
                                
                                Image(systemName: "rectangle.portrait.slash")
                                
                            }
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 153))
                            .onHover { hovering in prax.hoveredButton = hovering ? 153 : nil }
                            
                        }
                        .disabled(mergedPage.skippedPages == 0)
                        .opacity(mergedPage.skippedPages == 0 ? 0.25 : 1)
                        
                        GridRow {
                            
                            if mergedPage.pageItems.count == 1 {
                                Text("Skip This Page")
                            }
                            else if mergedPage.pageItems.count == 2 {
                                Text("Skip Both Pages")
                            }
                            else {
                                Text( "Skip All \(mergedPage.pageItems.count) Pages")
                            }
                            
                            Button {
                                mergedPage.skipAllPages()
                                dismiss() }
                            label: {
                                
                                Image(systemName: "rectangle.portrait.slash")
                                
                            }
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 156))
                            .onHover { hovering in prax.hoveredButton = hovering ? 156 : nil }
                            
                        }
                        .disabled(mergedPage.pageItems.count <= mergedPage.skippedPages)
                        .opacity(mergedPage.pageItems.count <= mergedPage.skippedPages ? 0.25 : 1)
                        
                        GridRow {
                            if mergedPage.pageItems.count < 2 {
                                Text("Delete This Page")
                            }
                            else {
                                Text("Delete This Merged Page")
                            }
                            Button {
                                prax.document.mergedPages.removeAll(where: { mergedPage in
                                    mergedPage == self.mergedPage
                                })
                                
                                dismiss() }
                            label: { Image(systemName: "trash")   }
                                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 150))
                                .onHover { hovering in
                                    prax.hoveredButton = hovering ? 150 : nil
                                }
                                .help("Delete page")
                            
                            
                        }
                        
                        
                    }
                    
                }
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.blue, lineWidth: 3) )
                
                
                if prax.document.mergedPages.count > 1 {
                    Divider()
                    
                    GroupBox {
                        
                        if prax.document.mergedPages.count == 2 {
                            Text("Other Merged Page")
                        }
                        else {
                            Text("\(prax.document.mergedPages.count - 1 ) other Merged Pages")
                        }
                        
                        Grid(alignment: .trailing) {
                            
                            GridRow {
                                
                                if prax.document.totalPageItems == 2 {
                                    Text("Include Both Page Items")
                                }
                                else {
                                    Text("Include All \(prax.document.totalPageItems) Page Items")
                                }
                                
                                
                                Button {
                                    prax.document.includeAllPages()
                                    dismiss() }
                                label: {
                                    
                                    Image(systemName: "rectangle.portrait.slash")
                                    
                                }
                                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 153))
                                .onHover { hovering in prax.hoveredButton = hovering ? 153 : nil }
                                
                            }
                            .disabled(mergedPage.skippedPages == 0)
                            .opacity(mergedPage.skippedPages == 0 ? 0.25 : 1)
                            
                            GridRow {
                                if prax.document.totalPageItems == 2 {
                                    Text("Skip Both Page Items")
                                }
                                else {
                                    Text("Skip All \(prax.document.totalPageItems) Page Items")
                                }
                                
                                Button {
                                    
                                    prax.document.skipAllPages()
                                    dismiss() }
                                label: {
                                    
                                    Image(systemName: "rectangle.portrait.slash")
                                    
                                }
                                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 176))
                                .onHover { hovering in prax.hoveredButton = hovering ? 176 : nil }
                                
                            }
                            .disabled(mergedPage.pageItems.count <= mergedPage.skippedPages)
                            .opacity(mergedPage.pageItems.count <= mergedPage.skippedPages ? 0.25 : 1)
                            
                            GridRow {
                                if prax.document.mergedPages.count == 2 {
                                    Text("Delete Both Merged Pages")
                                }
                                else {
                                    Text("Delete All \(prax.document.totalPageItems) Merged Pages")
                                }
                                Button {
                                    prax.document.mergedPages.removeAll()
                                    prax.document.refreshMergedDocument()
                                    dismiss() }
                                label: { Image(systemName: "trash")   }
                                    .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 150))
                                    .onHover { hovering in
                                        prax.hoveredButton = hovering ? 150 : nil
                                    }
                                    .help("Delete page")
                                
                            }
                            
                        }
                    }
                    
                    
                }
                
                Divider()
                
                GroupBox {
                    Text("Julie d'Prax = \(mergedPage.pageItems.count) Source Pages")
                }
                
            }
            .padding(.top, 20)
            .padding(.horizontal, 10)
            .background(PraxGradient(0).ignoresSafeArea())
            .foregroundColor(.white)
            //       .popoverTip(theTip)
        }
    }

}



nonisolated struct ItemID: Identifiable, Hashable, Sendable {
    let id: UUID
    init(_ id: UUID) { self.id = id }
}

nonisolated struct SectionID: Identifiable, Hashable, Sendable {
    let id: UUID
    init(_ id: UUID) { self.id = id }
}



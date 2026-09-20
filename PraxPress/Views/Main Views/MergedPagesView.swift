//
//  MergedPagesView.swift
//  PraxPress
//
//  Created by Elmer Cat on 9/5/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

private let DEBUG_LOGS = true



struct MergedPagesView: View {
    
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    
 //   @State private var selection = SelectionModel<UUID>()
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var dragStart: CGPoint? = nil
    @State private var dragRect: CGRect? = nil
    @State private var dragBaseSelection: Set<UUID> = []
    @State private var dragAnchor: UUID? = nil
    
    var body: some View {
        
        @Bindable var prax = prax
        
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 16) {
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
                    .background(.mergedPDFViewBackground)
                    .coordinateSpace(name: "ScrollSpace")
                    .onPreferenceChange(RowFramePreferenceKey.self) { frames in rowFrames = frames }
                    .gesture(dragSelectionGesture(selection: prax.selectionModel))
            }
        }
        .onGeometryChange(for: CGSize.self) { windowGeometry in return windowGeometry.size }
        action: { oldValue, newValue in prax.mergedPagesSize = newValue }
        
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
    
    
    
}

struct MergedPageView: View {
    @Environment(PraxModel.self) private var prax
    let mergedPage: MergedPage
    @State private var dropTargeted: Bool = false
    
    var body: some View {
        @Bindable var prax = prax
        GroupBox {
            VStack {
                SectionHeaderView(mergedPage: mergedPage, isSelected: prax.selectedPages.contains(mergedPage.id), highlightState: .none)


                ForEach(mergedPage.pageItems) { pageItem in
                    PageItemView(pageItem: pageItem, isSelected: prax.selectedPages.contains(pageItem.id), highlightState: .none)
                        .frame(height: prax.pageItemHeight)
                        .reportRowFrame(id: pageItem.id)
                        .onTapGesture {
                            prax.selectionModel.clearAndSelect(pageItem.id)
                            prax.selectedPageItem = pageItem
                            prax.selectedPages = prax.selectionModel.selected
                        }
                        .highPriorityGesture(
                            TapGesture()
                                .modifiers(.option)
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
                        .draggable(PageItemTransfer(pageItem: pageItem))

                }
                .padding(5)
 
                Divider()
            }
            .padding(5)
        }
        .background(dropTargeted ? Color.blue : Color.cyan)
        .dropDestination(
            for: SourceFileTransfer.self,
            action: {
                items, location in
                for item in items {
                    prax.document.addPagesFromSourceFilePayload(item.payload, at: IndexPath(item: -1, section: 0), toMergedPage: mergedPage)
                    
                }
                return true},
            isTargeted: { targeted in dropTargeted = targeted })
 /*       .dropDestination(for: SourceFileTransfer.self, action: { files, session in
            print("Page Item View - SourceFileTransfer - /n", files, session)
            return true
        })
*/
        
/*
        .dropDestination(for: PageTransfer.self, action: { files, session in
            print("Page Item View - PageTransfer - /n", files, session)
            return true
        })
*/
        

    }
}

struct MergedPagesList: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PersistenceController.self) private var persistence
    
    @Environment(PraxModel.self) private var praxModel
    
    @State private var dropTargeted: Bool = false
    
    var body: some View {
        @Bindable var document = document
        @Bindable var prax = praxModel

        ScrollView {
            
            Grid(verticalSpacing: 20) {
                ForEach(document.mergedPages) { mergedPage in
                    MergedPageView(mergedPage: mergedPage)
                        .reportRowFrame(id: mergedPage.id)

                }
                
            }
            
        }
        .background(dropTargeted ? PraxGradient(3) : PraxGradient(2))
        
        .dropDestination(
            for: SourceFileTransfer.self,
            action: {
                items, location in
                for item in items {
                    document.addPagesFromSourceFilePayload(item.payload, at: IndexPath(item: 0, section: -1) )
                }
               return true},
            isTargeted: { targeted in dropTargeted = targeted })

        .onChange(of: prax.selectedMergedPages) { print(".onChange(of: prax.selectedMergedPages) {")  }
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



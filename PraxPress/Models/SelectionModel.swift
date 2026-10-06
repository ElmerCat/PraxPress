//
//  SelectionModel.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/4/26.
//

import SwiftUI

@Observable
final class SelectionModel<ID: Hashable & Sendable> {
    var selected: Set<ID> = []
    var anchor: ID? = nil
    var lastClicked: ID? = nil
    
    
    func isSelected(_ id: ID) -> Bool { selected.contains(id) }
    
    func clearAndSelect(_ id: ID) {
        selected = [id]
        anchor = id
        lastClicked = id
    }
    
    func toggle(_ id: ID) {
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
        lastClicked = id
        if anchor == nil { anchor = id }
    }
    
    func selectRange(allIDs: [ID], to id: ID, additive: Bool) {
        guard let anchor = anchor ?? lastClicked,
              let start = allIDs.firstIndex(of: anchor),
              let end = allIDs.firstIndex(of: id) else {
            clearAndSelect(id)
            return
        }
        let lower = min(start, end)
        let upper = max(start, end)
        let rangeSet = Set(allIDs[lower...upper])
        if additive { selected.formUnion(rangeSet) } else { selected = rangeSet }
        lastClicked = id
    }
    
    func setSelected(_ ids: Set<ID>, keepAnchor anchorID: ID?) {
        selected = ids
        if let anchorID { anchor = anchorID }
    }
}


struct RowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID : CGRect], nextValue: () -> [UUID : CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct RowFrameReporter<ID: Hashable & Sendable>: ViewModifier {
    let id: ID
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: RowFramePreferenceKey.self,
                            value: [uuidFor(id): geo.frame(in: .named("ScrollSpace"))]
                        )
                }
            )
    }
    
    func uuidFor(_ id: ID) -> UUID {
        if let uuid = id as? UUID { return uuid }
        var hasher = Hasher()
        id.hash(into: &hasher)
        let hash = hasher.finalize()
        let bytes = withUnsafeBytes(of: hash.bigEndian, Array.init)
        var uuidBytes = [UInt8](repeating: 0, count: 16)
        for i in 0..<min(bytes.count, 16) { uuidBytes[i] = bytes[i] }
        return UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5],
            uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9],
            uuidBytes[10], uuidBytes[11], uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        ))
    }
}

extension View {
    func reportRowFrame<ID: Hashable & Sendable>(id: ID) -> some View {
        modifier(RowFrameReporter(id: id))
    }
}

struct DragSelectionOverlay<ID: Hashable & Sendable>: View {
    @Binding var dragRect: CGRect?
    let rowFrames: [UUID: CGRect]
    let allIDs: [ID]
    let idToUUID: (ID) -> UUID
    let onSetSelection: (Set<ID>) -> Void
    
    var body: some View {
        ZStack {
            if let rect = dragRect {
                Rectangle()
                    .fill(.tint.opacity(0.15))
                    .overlay(Rectangle().stroke(.tint, lineWidth: 1))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .allowsHitTesting(false)
                    .onChange(of: rect) { _, newRect in
                        updateSelection(newRect)
                    }
                    .onAppear { updateSelection(rect) }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func updateSelection(_ rect: CGRect) {
        var result = Set<ID>()
        for id in allIDs {
            let uuid = idToUUID(id)
            if let frame = rowFrames[uuid], frame.intersects(rect) {
                result.insert(id)
            }
        }
        onSetSelection(result)
    }
}


//
//  Prax.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/12/26.
//

import SwiftUI
import PDFKit


func scalePDFViewToFitViewSize(_ pdfView: PDFView, _ viewSize: CGSize, _ direction: PDFDisplayDirection, forPDFDocument pdfDocument: PDFDocument, pageMargin: CGSize = .zero, viewMargin: CGSize = .zero) {
    guard let pdfDocument = pdfView.document else { return }
    
    let documentSize = pdfDocumentSize(pdfDocument)
    let viewSize = viewSize + viewMargin
    
    switch direction {
    case .horizontal:
        pdfView.scaleFactor = viewSize.width  / documentSize.width
        
    case .vertical:
        var documentHeight = pageMargin.height
        documentHeight += documentHeight * Double(pdfDocument.pageCount)
        documentHeight += documentSize.height
        
        pdfView.scaleFactor = (viewSize.height) / documentHeight
    @unknown default:
        return
    }
}

func pdfDocumentSize(_ pdfDocument: PDFDocument) -> CGSize {
    var pdfSize: CGSize  = .zero
    for index in 0...pdfDocument.pageCount - 1 {
        guard let pdfPage = pdfDocument.page(at: index) else { return .zero }
        let crop = pdfPage.bounds(for: .cropBox)
        pdfSize.height += crop.height
        pdfSize.width = max(pdfSize.width, crop.width)}
    return pdfSize
}

enum EditMode: String, CaseIterable {
    case merge = "Edit Merge"
    case data = "Edit Data"
    case prax = "Edit Prax"
    
    var color: Color { switch self {
    case .merge:
        return .pink
    case .data:
        return .blue
    case .prax:
        return .orange } }
    
    var icon: String { switch self {
    case .merge:
        return "apple.logo"
    case .data:
        return "swift"
    case .prax:
        return "gear" }}
}

enum PraxPressMode: String, CaseIterable {
    case data = "Data Mode"
    case merge = "Merge Mode"
    case prax = "Prax Mode"
    
    var color: Color { switch self {
    case .merge:
        return .pink
    case .data:
        return .blue
    case .prax:
        return .orange } }
    
    var icon: String { switch self {
    case .merge:
        return "apple.logo"
    case .data:
        return "swift"
    case .prax:
        return "gear" }}
}

enum AnnotationSaveMode: String, CaseIterable {
    case editable = "Unlocked"
    case locked = "Locked"
    case burnIn = "Burn In"
    
    var color: Color { switch self {
    case .editable:
        return .green
    case .locked:
        return .blue
    case .burnIn:
        return .orange } }
    
    var icon: String { switch self {
    case .editable:
        return "lock.open"
    case .locked:
        return "lock"
    case .burnIn:
        return "burn" }}
}


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

class Prax {
    static let pdfPageBreakMargins = NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    static let filechars = Set(",./?;:'\"[{]}!@#$%^&*()|\\")
    static let decimals = Set("0123456789.-+")
    static let fileTypes = ["pdf", "png", "jpeg", "jpg", "gif", "heic"]
    
 }

enum ImportSizingMode: String, CaseIterable, Identifiable, Codable {
    case fileSizeLimit
    case targetInches
    var id: String { rawValue }
}

nonisolated struct ImageImportOptions: Equatable, Codable, Sendable {
    
    var cropLeft: Double = 0
    var cropRight: Double = 0
    var cropTop: Double = 0
    var cropBottom: Double = 0
    
    var scaleDown: Double = 1.0
    
    var brightness: Double = 0.0
    var contrast: Double = 1.0
    var exposure: Double = 0.0
    var sharpness: Double = 0.0
    
    // nil means "resolve from saved defaults"
    var sizingMode: ImportSizingMode = .fileSizeLimit
    
    // used in .fileSizeLimit mode
    var sizeLimitKB: Int = 1024
    
    // used in .targetInches mode
    var targetWidthInches: Double = 8.5
    var targetHeightInches: Double = 11.0
    
    static let neutral = ImageImportOptions()
}

public struct StorageValue<Value: Codable>: RawRepresentable {
    
    /// Create a storage value.
    public init(_ value: Value? = nil) {
        self.value = value
    }
    
    /// Create a storage value with a JSON encoded string.
    public init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode(Value.self, from: data)
        else { return nil }
        self = .init(result)
    }
    
    /// The stored value.
    public var value: Value?
}

public extension StorageValue {
    
    /// Whether the storage value contains an actual value.
    var hasValue: Bool {
        value != nil
    }
    
    /// A JSON string representation of the storage value.
    var jsonString: String {
        guard
            let data = try? JSONEncoder().encode(value),
            let result = String(data: data, encoding: .utf8)
        else { return "" }
        return result
    }
    
    /// A JSON string representation of the storage value.
    var rawValue: String {
        jsonString
    }
}

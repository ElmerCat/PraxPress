//
//  Prax.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/12/26.
//

import SwiftUI
import PDFKit

// MARK: - The Prax class has static values which can be used used anywhere.



class Prax {
    static let pdfPageBreakMargins = NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    static let filechars = Set(",./?;:'\"[{]}!@#$%^&*()|\\")
    static let decimals = Set("0123456789.-+")
    static let fileTypes = ["pdf", "png", "jpeg", "jpg", "gif", "heic"]
    
    static let filenameStyle = URL.FormatStyle(scheme: .never,
                                               user: .never,
                                               password: .never,
                                               host: .always,
                                               port: .never,
                                               path: .always,
                                               query: .never,
                                               fragment: .never)
}


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
    if pdfDocument.pageCount > 0 {
        for index in 0...pdfDocument.pageCount - 1 {
            guard let pdfPage = pdfDocument.page(at: index) else { return .zero }
            let crop = pdfPage.bounds(for: .cropBox)
            pdfSize.height += crop.height
            pdfSize.width = max(pdfSize.width, crop.width)}
    }
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

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
    static let editingPDFPageBreakMargins = NSEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
    static let mergedPDFPageBreakMargins = NSEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
    
    
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


enum SourceFileStatus: String, Codable, Hashable, Comparable {
    static func < (lhs: SourceFileStatus, rhs: SourceFileStatus) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    case okay = "Source Files"
    case trashed = "Files in the Trash"
    case bad = "Files that can't be found"
}

enum SourceFileType: String, Codable, Hashable, Comparable {
    static func < (lhs: SourceFileType, rhs: SourceFileType) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    case pdf = "pdf"
    case image = "image"
    case text = "text"
    case other = "other"
}


enum ViewScaleMode: Int {
    case vertical
    case horizontal
    case fit
    case user
}


nonisolated func fileAttributesForBookmark(_ bookmark: Data) async throws -> [FileAttributeKey: Any] {
    var isStale = false
    guard let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            else {  print("fileAttributesForBookmark - Error resolvingBookmarkData") ; return [:] }
    let needsStop = url.startAccessingSecurityScopedResource()
    defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return attributes
    
}





func formatFileSize(_ size: Int) -> String {
    if size < 1000 { return "\(size) bytes"}
    else if size < 1000000 { return "\(size / 1000) KB"}
    else if size < 1000000000 { return "\(size / 1000000) MB"}
    else if size < 1000000000000 { return "\(size / 1000000000) GB"}
    else  { return "\(size / 1000000000000) TB"}
    
}

func formatSmartDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()
    
    // 1. If the date is today: 7:45 PM
    if calendar.isDateInToday(date) {
        return date.formatted(
            .dateTime
                .hour(.conversationalDefaultDigits(amPM: .abbreviated))
                .minute(.twoDigits)
        )
    }
    
    // 2. If within the last 12 months: Apr 7
    // Calculate the difference in months between the date and now
    let monthDifference = calendar.dateComponents([.month], from: date, to: now).month ?? 0
    
    if date < now && monthDifference < 12 {
        return date.formatted(
            .dateTime
                .month(.abbreviated)
                .day(.defaultDigits)
        )
    }
    
    // 3. Earlier still (or fallback for future dates): 2026
    return date.formatted(.dateTime.year(.defaultDigits))
}


func scalePDFViewToFitViewSize(_ pdfView: PDFView, _ viewSize: CGSize, _ direction: PDFDisplayDirection? = nil, forPDFDocument pdfDocument: PDFDocument, pageMargin: CGSize = .zero, viewMargin: CGSize = CGSize(width: 30, height: 10)) {
    guard let pdfDocument = pdfView.document else { return }
    
    let documentSize = pdfDocumentSize(pdfDocument)
    let viewSize = viewSize - viewMargin
    
    let verticalScale = viewSize.height / documentSize.height
    let horizontalScale = viewSize.width / documentSize.width
    var scaleFactor: CGFloat
    switch direction {
   
    
    case .vertical?: scaleFactor = verticalScale
    case .horizontal?: scaleFactor = horizontalScale
        default:  scaleFactor = min(verticalScale, horizontalScale) }
 //   scaleFactor = scaleFactor * 0.5
    pdfView.scaleFactor = scaleFactor
    
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



enum FileGroup: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    case imported = "Main File Group"
    case exported = "Exported File Group"
    case locked = "Locked File Group"
    
    var color: Color { switch self {
    case .imported:
        return .pink
    case .exported:
        return .blue
    case .locked:
        return .orange } }
    
    var icon: String { switch self {
    case .imported:
        return "text.document.fill"
    case .exported:
        return "document.badge.gearshape.fill"
    case .locked:
        return "lock.document.fill" }}
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

//
//  Prax.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/12/26.
//

import SwiftUI

class Prax {
    static let decimals = Set("0123456789.-+")
    static let fileTypes = ["pdf", "png", "jpeg", "jpg", "gif", "heic"]
    
 }

enum ImportSizingMode: String, CaseIterable, Identifiable, Codable {
    case fileSizeLimit
    case targetInches
    var id: String { rawValue }
}

struct ImageImportOptions: Equatable, Codable, Sendable {
    
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

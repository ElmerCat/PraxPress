//
//  Prax.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/12/26.
//

import SwiftUI

class Prax {
    static let decimals = Set("0123456789.-+")
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

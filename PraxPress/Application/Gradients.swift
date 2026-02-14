//
//  Gradients.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/13/26.
//

import SwiftUI
func PraxGradient(_ style: Int? = nil) -> MeshGradient {
    
    switch style {
    case 0:
        MeshGradient(
            width: 2,
            height: 2,
            points: [
                [0.0, 0.0], [1.0, 0.0],
                [0.0, 1.0], [1.0, 1.0]
                
            ],
            colors: [
                .black,.blue.opacity(0.5),
                .blue.opacity(0.5), .black
            ])
    case 1:
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .clear,.blue,.clear,
                .blue, .clear, .blue,
                .clear, .green, .clear
            ]
        )
    default:
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .white,.black,.white,
                .blue, .blue, .blue,
                .white, .green, .white
            ])
    }
    

}

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data) else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return result
    }
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
#Preview {
    PraxGradient(0)
    PraxGradient(1)
}

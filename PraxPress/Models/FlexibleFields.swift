//
//  FlexibleFields.swift
//  PraxPress
//
//  Created by Elmer Cat on 3/17/26.
//


import Foundation


// Keep your existing FlexibleFields and FieldValue definitions above…

// MARK: - Free encode/decode helpers (inherently nonisolated)
func encodeFlexibleFields(_ value: FlexibleFields) -> Data? {
    do {
        return try JSONEncoder().encode(value)
    } catch {
        print("Failed to encode FlexibleFields: \(error)")
        return nil
    }
}

func decodeFlexibleFields(from data: Data) -> FlexibleFields? {
    do {
        return try JSONDecoder().decode(FlexibleFields.self, from: data)
    } catch {
        print("Failed to decode FlexibleFields: \(error)")
        return nil
    }
}

public struct FlexibleFields: Codable, Hashable, Sendable {
    public var storage: [String: FieldValue] = [:]

    public init(storage: [String: FieldValue] = [:]) {
        self.storage = storage
    }

    public subscript(key: String) -> FieldValue? {
        get { storage[key] }
        set { storage[key] = newValue }
    }
}

public enum FieldValue: Codable, Hashable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum Kind: String, Codable {
        case string
        case int
        case double
        case bool
        case date
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .type)
        switch kind {
        case .string:
            self = .string(try container.decode(String.self, forKey: .value))
        case .int:
            self = .int(try container.decode(Int.self, forKey: .value))
        case .double:
            self = .double(try container.decode(Double.self, forKey: .value))
        case .bool:
            self = .bool(try container.decode(Bool.self, forKey: .value))
        case .date:
            let s = try container.decode(String.self, forKey: .value)
            guard let date = ISO8601DateFormatter().date(from: s) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .value, in: container,
                    debugDescription: "Invalid ISO8601 date string: \(s)"
                )
            }
            self = .date(date)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let s):
            try container.encode(Kind.string, forKey: .type)
            try container.encode(s, forKey: .value)
        case .int(let i):
            try container.encode(Kind.int, forKey: .type)
            try container.encode(i, forKey: .value)
        case .double(let d):
            try container.encode(Kind.double, forKey: .type)
            try container.encode(d, forKey: .value)
        case .bool(let b):
            try container.encode(Kind.bool, forKey: .type)
            try container.encode(b, forKey: .value)
        case .date(let date):
            try container.encode(Kind.date, forKey: .type)
            let s = ISO8601DateFormatter().string(from: date)
            try container.encode(s, forKey: .value)
        }
    }

    public var stringValue: String? { if case .string(let s) = self { s } else { nil } }
    public var intValue: Int? { if case .int(let i) = self { i } else { nil } }
    public var doubleValue: Double? { if case .double(let d) = self { d } else { nil } }
    public var boolValue: Bool? { if case .bool(let b) = self { b } else { nil } }
    public var dateValue: Date? { if case .date(let d) = self { d } else { nil } }
}

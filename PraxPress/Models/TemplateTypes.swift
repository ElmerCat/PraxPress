//
//  TemplateTypes.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/22/26.
//


import Foundation

// MARK: - Analysis Output Types

/// One segment of the discovered template
enum TemplateSegment: Codable, Hashable {
    /// Fixed text present in every input line
    case literal(String)
    /// A variable field, identified by its zero-based index
    case field(Int)
}

/// How the pattern was detected
enum AnalysisMethod: String, Codable, CaseIterable {
    case delimiter
    case alignment
    case manual
}

/// A characterization of observed values in a single field
struct FieldProfile: Codable, Hashable, Identifiable {
    var id: Int { index }
    let index: Int
    /// Every distinct value seen in this field across all source lines
    let samples: [String]
    /// A regex pattern that matches all observed samples (nil if too heterogeneous)
    let inferredPattern: String?
    /// Whether all samples share the same character count
    let fixedWidth: Bool
    /// Min and max observed character counts
    let widthRange: ClosedRange<Int>
}

/// Complete result of analyzing a batch of lines — everything the UI step needs
struct AnalysisResult: Codable, Identifiable {
    let id: UUID
    /// Ordered segments composing the template
    let segments: [TemplateSegment]
    /// Extracted values: [lineIndex][fieldIndex]
    let extractedValues: [[String]]
    /// Per-field characterization
    let fieldProfiles: [FieldProfile]
    /// Original input lines
    let sourceLines: [String]
    /// Detection method used
    let method: AnalysisMethod
    /// Delimiter character (only for .delimiter method)
    let delimiter: String?
    /// 0…1 confidence score
    let confidence: Double
    /// Lines (by index) that didn't fully match the discovered template
    let mismatchedLines: [Int]
}

//
//  TemplateAnalyzer.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/22/26.
//

// TemplateAnalyzer.swift

import Foundation

struct TemplateAnalyzer {

    // MARK: - Public Entry Point

    func analyze(
        lines: [String],
        manualSplitPoints: [Int]? = nil
    ) -> AnalysisResult? {
        let trimmed = lines.map { $0.trimmingCharacters(in: .newlines) }
            .filter { !$0.isEmpty }
        guard trimmed.count >= 2 else { return nil }

        if let splits = manualSplitPoints {
            return analyzeWithManualSplits(lines: trimmed, splits: splits)
        }

        if let result = analyzeByDelimiter(lines: trimmed) {
            return result
        }

        return analyzeByAlignment(lines: trimmed)
    }

    // MARK: - Delimiter-Based Analysis

    private static let candidateDelimiters: [(String, Character?)] = [
        ("\t", "\t"),
        ("|", "|"),
        (";", ";"),
        (",", ","),
    ]

    private func analyzeByDelimiter(lines: [String]) -> AnalysisResult? {
        var bestResult: AnalysisResult?
        var bestFieldCount = 0

        for (delim, _) in Self.candidateDelimiters {
            guard let result = tryDelimiter(delim, lines: lines) else { continue }
            // Prefer the delimiter that yields the most fields
            let fc = result.fieldProfiles.count
            if fc > bestFieldCount {
                bestFieldCount = fc
                bestResult = result
            }
        }

        // Also try multi-space as a delimiter
        if let result = tryMultiSpace(lines: lines) {
            let fc = result.fieldProfiles.count
            if fc > bestFieldCount {
                bestFieldCount = fc
                bestResult = result
            }
        }

        return bestResult
    }

    private func tryDelimiter(_ delimiter: String, lines: [String]) -> AnalysisResult? {
        let splitLines = lines.map { $0.components(separatedBy: delimiter) }

        // All lines must have the same field count
        let fieldCounts = Set(splitLines.map(\.count))
        guard fieldCounts.count == 1,
              let fieldCount = fieldCounts.first,
              fieldCount >= 2 else {
            return nil
        }

        // Every column is a field — no constant promotion
        var segments: [TemplateSegment] = []
        for i in 0..<fieldCount {
            segments.append(.field(i))
            if i < fieldCount - 1 {
                segments.append(.literal(delimiter))
            }
        }

        let extractedValues: [[String]] = splitLines

        let confidence: Double = 0.95
        let profiles = buildProfiles(extractedValues: extractedValues, fieldCount: fieldCount)

        return AnalysisResult(
            id: UUID(),
            segments: segments,
            extractedValues: extractedValues,
            fieldProfiles: profiles,
            sourceLines: lines,
            method: .delimiter,
            delimiter: delimiter,
            confidence: confidence,
            mismatchedLines: []
        )
    }

    private func tryMultiSpace(lines: [String]) -> AnalysisResult? {
        let regex = try! NSRegularExpression(pattern: "\\s{2,}")
        let splitLines: [[String]] = lines.map { line in
            let range = NSRange(line.startIndex..., in: line)
            let replaced = regex.stringByReplacingMatches(
                in: line, range: range, withTemplate: "\u{FFFF}"
            )
            return replaced.components(separatedBy: "\u{FFFF}")
        }

        let fieldCounts = Set(splitLines.map(\.count))
        guard fieldCounts.count == 1,
              let fieldCount = fieldCounts.first,
              fieldCount >= 2 else {
            return nil
        }

        var segments: [TemplateSegment] = []
        for i in 0..<fieldCount {
            segments.append(.field(i))
            if i < fieldCount - 1 {
                segments.append(.literal("  "))
            }
        }

        let extractedValues: [[String]] = splitLines
        let confidence: Double = 0.85
        let profiles = buildProfiles(extractedValues: extractedValues, fieldCount: fieldCount)

        return AnalysisResult(
            id: UUID(),
            segments: segments,
            extractedValues: extractedValues,
            fieldProfiles: profiles,
            sourceLines: lines,
            method: .delimiter,
            delimiter: "  ",
            confidence: confidence,
            mismatchedLines: []
        )
    }

    // MARK: - Alignment-Based Analysis

    private func analyzeByAlignment(lines: [String]) -> AnalysisResult? {
        guard lines.count >= 2 else { return nil }

        // Find the longest common substrings that appear in ALL lines, in order
        guard let frame = findCommonFrame(lines: lines), !frame.isEmpty else {
            return nil
        }

        // Use the frame to split each line
        var extractedValues: [[String]] = []
        var mismatchedLines: [Int] = []

        for (i, line) in lines.enumerated() {
            if let values = extractFields(from: line, usingFrame: frame) {
                extractedValues.append(values)
            } else {
                mismatchedLines.append(i)
                extractedValues.append([])
            }
        }

        // Field count = frame.count + 1 (before first literal, between each, after last)
        let rawFieldCount = frame.count + 1

        // Determine which field positions actually carry content
        var activeFields: [Int] = []
        for col in 0..<rawFieldCount {
            let hasContent = extractedValues.contains { row in
                col < row.count && !row[col].isEmpty
            }
            if hasContent { activeFields.append(col) }
        }

        guard !activeFields.isEmpty else { return nil }

        // Build segments
        var segments: [TemplateSegment] = []
        var fieldIdx = 0

        for col in 0..<rawFieldCount {
            if activeFields.contains(col) {
                segments.append(.field(fieldIdx))
                fieldIdx += 1
            }
            if col < frame.count {
                segments.append(.literal(frame[col]))
            }
        }

        let actualFieldCount = fieldIdx

        // Normalize extracted values to only active fields
        let normalizedValues: [[String]] = extractedValues.map { row in
            if row.isEmpty { return [String](repeating: "", count: actualFieldCount) }
            return activeFields.map { col in
                col < row.count ? row[col] : ""
            }
        }

        let matchRatio = Double(lines.count - mismatchedLines.count) / Double(lines.count)
        let confidence = matchRatio * 0.85

        let profiles = buildProfiles(extractedValues: normalizedValues, fieldCount: actualFieldCount)

        return AnalysisResult(
            id: UUID(),
            segments: segments,
            extractedValues: normalizedValues,
            fieldProfiles: profiles,
            sourceLines: lines,
            method: .alignment,
            delimiter: nil,
            confidence: confidence,
            mismatchedLines: mismatchedLines
        )
    }

    /// Find ordered literal substrings common to ALL lines.
    /// Uses recursive longest-common-substring anchoring.
    private func findCommonFrame(lines: [String]) -> [String]? {
        guard lines.count >= 2 else { return nil }

        // Start by finding common substrings between first two lines
        var frame = orderedCommonSubstrings(lines[0], lines[1], minLength: 2)

        // Validate and refine against every remaining line
        for line in lines.dropFirst(2) {
            frame = refineFrame(frame, against: line)
            if frame.isEmpty { break }
        }

        // Filter out substrings that are likely coincidental
        let filtered = frame.filter { seg in
            // Keep if length >= 2, or if it's structural punctuation
            if seg.count >= 2 { return true }
            let structural: Set<Character> = ["/", "-", ":", ".", ",", "|", "#", "@", "(", ")", "[", "]"]
            return seg.count == 1 && structural.contains(seg.first!)
        }

        return filtered.isEmpty ? nil : filtered
    }

    /// Find ordered common substrings between two strings using dynamic programming.
    /// Returns substrings of at least `minLength` characters, in the order they appear.
    private func orderedCommonSubstrings(_ a: String, _ b: String, minLength: Int) -> [String] {
        let aArr = Array(a)
        let bArr = Array(b)
        let m = aArr.count
        let n = bArr.count

        guard m > 0, n > 0 else { return [] }

        // Find all common substrings using DP suffix approach, then chain them greedily
        // Step 1: Build suffix match length table
        // dp[i][j] = length of common substring ending at a[i-1], b[j-1]
        var dp = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 1...m {
            for j in 1...n {
                if aArr[i - 1] == bArr[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                }
            }
        }

        // Step 2: Collect all common substrings of length >= minLength
        struct Match: Comparable {
            let aStart: Int
            let bStart: Int
            let length: Int
            static func < (lhs: Match, rhs: Match) -> Bool {
                if lhs.aStart != rhs.aStart { return lhs.aStart < rhs.aStart }
                return lhs.length > rhs.length // prefer longer
            }
        }

        var matches: [Match] = []
        for i in 1...m {
            for j in 1...n {
                let len = dp[i][j]
                if len >= minLength {
                    // Only record if this is a maximal match (not extended at [i+1][j+1])
                    let isMaximal = (i == m || j == n || dp[i + 1][j + 1] == 0 || aArr[i] != bArr[j])
                    if isMaximal {
                        matches.append(Match(aStart: i - len, bStart: j - len, length: len))
                    }
                }
            }
        }

        // Step 3: Greedily select non-overlapping matches in order (longest first within position)
        matches.sort()

        var selected: [Match] = []
        var lastAEnd = 0
        var lastBEnd = 0

        for match in matches {
            if match.aStart >= lastAEnd && match.bStart >= lastBEnd {
                selected.append(match)
                lastAEnd = match.aStart + match.length
                lastBEnd = match.bStart + match.length
            }
        }

        // Step 4: Extract the actual substrings
        return selected.map { match in
            String(aArr[match.aStart..<(match.aStart + match.length)])
        }
    }

    /// Validate frame literals still appear in order within a new line, dropping any that don't.
    private func refineFrame(_ frame: [String], against line: String) -> [String] {
        var refined: [String] = []
        var searchStart = line.startIndex

        for literal in frame {
            if let range = line.range(of: literal, range: searchStart..<line.endIndex) {
                refined.append(literal)
                searchStart = range.upperBound
            }
        }

        return refined
    }

    /// Extract variable field values from a line using the known literal frame.
    /// Returns frame.count + 1 values (before first, between each pair, after last).
    private func extractFields(from line: String, usingFrame frame: [String]) -> [String]? {
        var fields: [String] = []
        var searchStart = line.startIndex

        for literal in frame {
            guard let range = line.range(of: literal, range: searchStart..<line.endIndex) else {
                return nil
            }
            let fieldValue = String(line[searchStart..<range.lowerBound])
            fields.append(fieldValue)
            searchStart = range.upperBound
        }

        // Trailing content after last literal
        let trailing = String(line[searchStart...])
        fields.append(trailing)

        return fields
    }

    // MARK: - Manual Split Points

    private func analyzeWithManualSplits(lines: [String], splits: [Int]) -> AnalysisResult? {
        let sortedSplits = splits.sorted()
        guard !sortedSplits.isEmpty else { return nil }

        var extractedValues: [[String]] = []
        var mismatchedLines: [Int] = []

        for (i, line) in lines.enumerated() {
            let chars = Array(line)
            var fields: [String] = []
            var prev = 0
            for split in sortedSplits {
                let clamped = min(split, chars.count)
                fields.append(String(chars[prev..<clamped]))
                prev = clamped
            }
            fields.append(String(chars[prev...]))

            if fields.allSatisfy({ $0.isEmpty }) {
                mismatchedLines.append(i)
            }
            extractedValues.append(fields)
        }

        let fieldCount = sortedSplits.count + 1

        var segments: [TemplateSegment] = []
        for i in 0..<fieldCount {
            segments.append(.field(i))
            if i < fieldCount - 1 {
                segments.append(.literal("│"))
            }
        }

        let profiles = buildProfiles(extractedValues: extractedValues, fieldCount: fieldCount)

        return AnalysisResult(
            id: UUID(),
            segments: segments,
            extractedValues: extractedValues,
            fieldProfiles: profiles,
            sourceLines: lines,
            method: .manual,
            delimiter: nil,
            confidence: 1.0,
            mismatchedLines: mismatchedLines
        )
    }

    // MARK: - Profile Building

    private func buildProfiles(extractedValues: [[String]], fieldCount: Int) -> [FieldProfile] {
        (0..<fieldCount).map { col in
            let samples = extractedValues.map { row in
                col < row.count ? row[col] : ""
            }
            let uniqueSamples = Array(Set(samples)).sorted()
            let lengths = samples.map(\.count)
            let minLen = lengths.min() ?? 0
            let maxLen = lengths.max() ?? 0
            let fixedWidth = (minLen == maxLen && minLen > 0)

            let pattern = inferPattern(from: uniqueSamples)

            return FieldProfile(
                index: col,
                samples: uniqueSamples,
                inferredPattern: pattern,
                fixedWidth: fixedWidth,
                widthRange: minLen...maxLen
            )
        }
    }

    private func inferPattern(from samples: [String]) -> String? {
        let nonEmpty = samples.filter { !$0.isEmpty }
        guard !nonEmpty.isEmpty else { return nil }

        let allDigits = nonEmpty.allSatisfy { $0.allSatisfy(\.isNumber) }
        if allDigits { return "\\d+" }

        let allAlpha = nonEmpty.allSatisfy { $0.allSatisfy(\.isLetter) }
        if allAlpha { return "[A-Za-z]+" }

        let allAlphanumeric = nonEmpty.allSatisfy { $0.allSatisfy { $0.isLetter || $0.isNumber } }
        if allAlphanumeric { return "[A-Za-z0-9]+" }

        // Words with spaces (like names, titles)
        let allWords = nonEmpty.allSatisfy { $0.allSatisfy { $0.isLetter || $0.isWhitespace } }
        if allWords { return "[A-Za-z ]+" }

        let dateLike = nonEmpty.allSatisfy { s in
            s.allSatisfy { $0.isNumber || $0 == "-" || $0 == "/" }
        }
        if dateLike { return "[0-9/\\-]+" }

        let emailLike = nonEmpty.allSatisfy { $0.contains("@") && $0.contains(".") }
        if emailLike { return "[^\\s]+@[^\\s]+" }

        return nil
    }
}

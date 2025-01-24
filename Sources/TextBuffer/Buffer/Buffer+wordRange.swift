//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

@usableFromInline
let wordBoundary: CharacterSet = .whitespacesAndNewlines
    .union(.punctuationCharacters)
    .union(.symbols)
    .union(.illegalCharacters)  // Not tested

extension CharacterSet {
    @usableFromInline
    static let nonWhitespaceOrNewlines: CharacterSet = .whitespacesAndNewlines.inverted
}

extension Buffer {
    @inlinable
    public func wordRange(
        for baseRange: Buffer.Range
    ) throws -> Buffer.Range {
        guard self.contains(range: baseRange)
        else { throw BufferAccessFailure.outOfRange(requested: baseRange, available: self.range) }

        // This bridging overhead isn't ideal while we operate on `Swift.String` as the `Buffer.Content`. It makes NSRange-based string enumeration easier. As long as `wordRange(for:)` is used to apply commands on the user's behalf via DeclarativeTextKit, we should be okay in practice even for longer document. Repeated calls to this function, e.g. in loops, could be a disaster, though. See commit d434030e6d9366941c5cc3fa9c6de860afb74710 for an approach that uses two while loops instead.
        let nsContent = (self.content as NSString)

        func expanding(
            range searchRange: NSRange,
            upToCharactersFrom characterSet: CharacterSet
        ) -> Buffer.Range {
            var expandedRange = searchRange
            expandedRange = expanding(range: expandedRange, upToCharactersFrom: characterSet, direction: .upstream)
            expandedRange = expanding(range: expandedRange, upToCharactersFrom: characterSet, direction: .downstream)
            return expandedRange
        }

        func expanding(
            range searchRange: NSRange,
            upToCharactersFrom characterSet: CharacterSet,
            direction: StringTraversalDirection
        ) -> Buffer.Range {
            switch direction {
            case .upstream:
                let matchedLocation = nsContent.locationUpToCharacter(
                    from: characterSet,
                    direction: .upstream,
                    in: self.range.prefix(upTo: searchRange)
                )
                return Buffer.Range(
                    startLocation: matchedLocation ?? self.range.location, // If nothing was found, expand to start of the available range.
                    endLocation: searchRange.endLocation
                )
            case .downstream:
                let matchedLocation = nsContent.locationUpToCharacter(
                    from: characterSet,
                    direction: .downstream,
                    in: self.range.suffix(after: searchRange)
                )
                return Buffer.Range(
                    startLocation: searchRange.location,
                    endLocation: matchedLocation ?? self.range.endLocation // If nothing was found, expand to end of the available range.
                )
            }
        }

        func trimmingWhitespace(range: Buffer.Range) -> Buffer.Range {
            var result = range

            // Trim trailing whitespace first, favoring upstream selection affinity, e.g. if `baseRange` is all whitespace.
            if let newEndLocation = nsContent.locationUpToCharacter(
                from: .nonWhitespaceOrNewlines,
                direction: .upstream,
                in: result.expanded(to: self.range, direction: .upstream))
            {
                result = Buffer.Range(
                    startLocation: result.location,
                    endLocation: max(newEndLocation, result.location)  // If newEndLocation < location, the whole of searchRange is whitespace.
                )
            }

            // Trim leading whitespace
            if let newStartLocation = nsContent.locationUpToCharacter(
                from: .nonWhitespaceOrNewlines,
                direction: .downstream,
                in: result.expanded(to: self.range, direction: .downstream))
            {
                result = Buffer.Range(
                    startLocation: min(newStartLocation, result.endLocation),  // If newStartLocation > endLocation, the whole searchRange is whitespace.
                    endLocation: result.endLocation
                )
            }

            return result
        }

        func nonWhitespaceLocation(closestTo location: Buffer.Location) -> Buffer.Location? {
            let downstreamNonWhitespaceLocation = nsContent.locationUpToCharacter(from: .nonWhitespaceOrNewlines, direction: .downstream, in: self.range.suffix(after: location))
            let upstreamNonWhitespaceLocation = nsContent.locationUpToCharacter(from: .nonWhitespaceOrNewlines, direction: .upstream, in: self.range.prefix(upTo: location))

            // Prioritize look-behind over look-ahead iff the location is downstream of a non-whitespace character (non-whitespace to the left of it) and the look-ahead is further away.
            if let upstreamNonWhitespaceLocation,
               let downstreamNonWhitespaceLocation,
               (upstreamNonWhitespaceLocation ..< location).count == 0,
               downstreamNonWhitespaceLocation > location {
                return upstreamNonWhitespaceLocation
            }

            return downstreamNonWhitespaceLocation ?? upstreamNonWhitespaceLocation
        }

        var resultRange = expanding(
            range: trimmingWhitespace(range: baseRange),
            upToCharactersFrom: wordBoundary
        )

        // If the result is an empty range, characters adjacent to the location were all `wordBoundary` characters. Then we need to try again with relaxed conditions, skipping over whitespace first. Try forward search, then backward.
        if resultRange.length == 0,
           let closestNonWhitespaceLocation = nonWhitespaceLocation(closestTo: resultRange.location) {
            resultRange = expanding(range: .init(location: closestNonWhitespaceLocation, length: 0), upToCharactersFrom: .whitespacesAndNewlines)
        }

        // When the input range covered only whitespace and nothing was found, discard the resulting empty range in favor of the original.
        if resultRange.length == 0, resultRange != baseRange {
            return baseRange
        }

        return resultRange
    }
}

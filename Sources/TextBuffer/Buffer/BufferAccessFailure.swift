//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct BufferAccessFailure: Error {
    public let label: String
    public let context: String?
    public let underlyingError: Error?

    fileprivate init(
        label: String,
        context: String? = nil,
        underlyingError: Error? = nil
    ) {
        self.label = label
        self.context = context
        self.underlyingError = underlyingError
    }

    public static func outOfRange(
        requested: Buffer.Range,
        available: Buffer.Range
    ) -> BufferAccessFailure {
        return BufferAccessFailure(
            label: "out of range",
            context: "tried to access (\(requested.location)..<\(requested.endLocation)) in available range (\(available.location)..<\(available.endLocation))"
        )
    }

    public static func outOfRange(
        location: Buffer.Location,
        length: Buffer.Length = 0,
        available: Buffer.Range
    ) -> BufferAccessFailure {
        return outOfRange(
            requested: .init(location: location, length: length),
            available: available
        )
    }

    public static func modificationForbidden(
        in requestedRange: Buffer.Range
    ) -> BufferAccessFailure {
        BufferAccessFailure(
            label: "modification not allowed",
            context: "tried to modify (\(requestedRange.location)..<\(requestedRange.endLocation))"
        )
    }

    public static func wrap(_ error: any Error) -> BufferAccessFailure {
        return error as? BufferAccessFailure
          ?? BufferAccessFailure(
            label: "",
            context: error.localizedDescription,
            underlyingError: error
          )
    }
}

extension BufferAccessFailure: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            label,
            (context ?? ""),
            // Do not include underlyingError here: we expect an error to be wrapped via `wrap(_:)`, which includes the wrapped errors description in `context`.
        ].filter(\.isEmpty.inverted).joined(separator: "\n")
    }
}

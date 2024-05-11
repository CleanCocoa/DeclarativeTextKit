//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct Line: Insertable {
    public let content: String

    public init(_ content: String) {
        self.content = content + "\n"
    }
}

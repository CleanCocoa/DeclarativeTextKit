//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public protocol Modification {
    func apply(to buffer: Buffer)
}

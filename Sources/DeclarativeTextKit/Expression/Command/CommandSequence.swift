//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct CommandSequenceFailure: Error {
    public let wrapped: Error
}

/// > Note: You don't create ``CommandSequence``s manually, you use `@CommandSequenceBuilder` blocks instead.
public struct CommandSequence: Command {
    public let commands: [any Command]

    init(_ commands: [any Command]) {
        self.commands = commands
    }

    public func evaluate(in buffer: Buffer) -> Result<Void, CommandSequenceFailure> {
        do {
            for command in commands {
                try command.evaluate(in: buffer)
            }
            return .success(())
        } catch {
            return .failure(CommandSequenceFailure(wrapped: error))
        }
    }
}

@resultBuilder
public struct CommandSequenceBuilder {
    public static func buildBlock(_ components: any Command...) -> CommandSequence {
        CommandSequence(components)
    }
}

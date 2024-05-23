//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct CommandSequenceFailure: Error {
    public let wrapped: Error
}

/// > Note: You don't create ``CommandSequence``s manually, you use `@CommandSequenceBuilder` blocks instead.
public struct CommandSequence {
    public let commands: [Command]

    init(_ commands: [Command]) {
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
    public static func buildPartialBlock(first: some Expression) -> CommandSequence {
        return CommandSequence([Command(wrapped: first)])
    }

    public static func buildPartialBlock(
        accumulated: CommandSequence,
        next: some Expression
    ) -> CommandSequence {
        return CommandSequence(
            accumulated.commands + [Command(wrapped: next)]
        )
    }
}

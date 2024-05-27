import Foundation

class LoggingUndoManager: UndoManager {
    private var level = 0
    var loggedMessages: [String] = []

    private func log(_ string: String) {
        loggedMessages.append((0..<level).reduce("") { str, _ in str + "  " } + string)
        print(loggedMessages.last!)
    }

    override func beginUndoGrouping() {
        log("will begin undo grouping")
        super.beginUndoGrouping()
        level += 1
        log("did begin undo grouping")
    }

    override func endUndoGrouping() {
        log("will end undo grouping")
        super.endUndoGrouping()
        level -= 1
        log("did end undo grouping")
    }

    override func undo() {
        log("will undo")
        super.undo()
        log("did undo")
    }

    override func undoNestedGroup() {
        log("will undo nested group")
        super.undoNestedGroup()
        log("did undo nested group")
    }

    override func redo() {
        log("will redo")
        super.redo()
        log("did redo")
    }
}

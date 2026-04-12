import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
nonisolated(unsafe) let assignedDelegate = delegate
app.delegate = assignedDelegate
app.run()

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var panelWindowController: PanelWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("MenuBarApp")
        ProcessInfo.processInfo.disableSuddenTermination()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "10Shot"
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        panelWindowController = PanelWindowController()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @objc func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // 右クリック → メニュー表示
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit 10Shot", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            // メニュー表示後にnilに戻す（左クリックが効くように）
            DispatchQueue.main.async { self.statusItem.menu = nil }
        } else {
            // 左クリック → パネル表示/非表示
            panelWindowController.toggle()
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

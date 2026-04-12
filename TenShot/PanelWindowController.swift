import Cocoa

class PanelWindowController: NSWindowController {

    convenience init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 600),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "10Shot"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = NSColor(red: 194/255, green: 154/255, blue: 108/255, alpha: 1)
        panel.isMovable = true
        panel.hasShadow = true

        self.init(window: panel)
        panel.contentViewController = PanelViewController()
    }

    func positionPanel() {
        guard let screen = NSScreen.main, let window = window else { return }
        let w: CGFloat = 300
        let h: CGFloat = screen.visibleFrame.height
        let x = screen.visibleFrame.maxX - w
        let y = screen.visibleFrame.minY
        window.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
    }

    func toggle() {
        if window?.isVisible == true {
            window?.orderOut(nil)
        } else {
            positionPanel()
            window?.orderFrontRegardless()
        }
    }
}

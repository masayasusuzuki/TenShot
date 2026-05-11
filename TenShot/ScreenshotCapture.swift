import Cocoa
import ScreenCaptureKit

@MainActor
final class ScreenshotCapture {

    static let shared = ScreenshotCapture()

    private var overlayWindows: [OverlayWindow] = []
    private var completion: ((NSImage?) -> Void)?

    func captureRegion(completion: @escaping (NSImage?) -> Void) {
        guard self.completion == nil else { return }
        self.completion = completion
        Task { @MainActor in
            await showOverlaysOnAllDisplays()
        }
    }

    private func showOverlaysOnAllDisplays() async {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            finish(with: nil)
            return
        }

        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true
            )
        } catch {
            finish(with: nil)
            return
        }

        for screen in screens {
            guard let scDisplay = matchSCDisplay(for: screen, in: content) else { continue }

            let overlay = OverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            overlay.level = .screenSaver
            overlay.isOpaque = false
            overlay.backgroundColor = .clear
            overlay.hasShadow = false
            overlay.ignoresMouseEvents = false
            overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

            let view = SelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.onSelect = { [weak self] rect in
                self?.performCapture(viewRect: rect, screen: screen, scDisplay: scDisplay)
            }
            view.onCancel = { [weak self] in
                self?.finish(with: nil)
            }
            overlay.contentView = view
            overlay.makeKeyAndOrderFront(nil)
            overlay.makeFirstResponder(view)
            overlayWindows.append(overlay)
        }

        if overlayWindows.isEmpty {
            finish(with: nil)
        }
    }

    private func matchSCDisplay(for screen: NSScreen, in content: SCShareableContent) -> SCDisplay? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let displayID = screen.deviceDescription[key] as? CGDirectDisplayID else {
            return nil
        }
        return content.displays.first(where: { $0.displayID == displayID })
    }

    private func performCapture(viewRect: CGRect, screen: NSScreen, scDisplay: SCDisplay) {
        dismissAllOverlays()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                guard let image = await self.captureDisplay(scDisplay, screen: screen) else {
                    self.finish(with: nil)
                    return
                }

                let scaleX = CGFloat(image.width) / screen.frame.width
                let scaleY = CGFloat(image.height) / screen.frame.height

                let cropRect = CGRect(
                    x: viewRect.minX * scaleX,
                    y: viewRect.minY * scaleY,
                    width: viewRect.width * scaleX,
                    height: viewRect.height * scaleY
                ).integral

                guard let cropped = image.cropping(to: cropRect) else {
                    self.finish(with: nil)
                    return
                }

                let scale = screen.backingScaleFactor
                let size = NSSize(
                    width: CGFloat(cropped.width) / scale,
                    height: CGFloat(cropped.height) / scale
                )
                self.finish(with: NSImage(cgImage: cropped, size: size))
            }
        }
    }

    private func captureDisplay(_ display: SCDisplay, screen: NSScreen) async -> CGImage? {
        do {
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            let scale = screen.backingScaleFactor
            config.width = Int(CGFloat(display.width) * scale)
            config.height = Int(CGFloat(display.height) * scale)
            config.showsCursor = false

            return try await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: config
            )
        } catch {
            return nil
        }
    }

    private func dismissAllOverlays() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
    }

    private func finish(with image: NSImage?) {
        dismissAllOverlays()
        overlayWindows.removeAll()
        let callback = completion
        completion = nil
        callback?(image)
    }
}

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class SelectionView: NSView {
    var onSelect: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: CGPoint?
    private var currentRect: CGRect?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        let tracking = NSTrackingArea(
            rect: bounds,
            options: [.cursorUpdate, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(tracking)
    }
    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            NSCursor.crosshair.set()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.setFillColor(NSColor(white: 0, alpha: 0.3).cgColor)
        if let sel = currentRect {
            let path = CGMutablePath()
            path.addRect(bounds)
            path.addRect(sel)
            ctx.addPath(path)
            ctx.fillPath(using: .evenOdd)

            ctx.setStrokeColor(NSColor.white.cgColor)
            ctx.setLineWidth(1.0)
            ctx.stroke(sel)

            let sizeText = "\(Int(sel.width)) × \(Int(sel.height))"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.white
            ]
            let text = NSAttributedString(string: sizeText, attributes: attrs)
            let textSize = text.size()
            let bgRect = NSRect(
                x: sel.minX,
                y: sel.maxY + 4,
                width: textSize.width + 10,
                height: textSize.height + 4
            )
            ctx.setFillColor(NSColor(white: 0, alpha: 0.7).cgColor)
            ctx.fill(bgRect)
            text.draw(at: NSPoint(x: bgRect.minX + 5, y: bgRect.minY + 2))
        } else {
            ctx.fill(bounds)
            drawGuidance(in: ctx)
        }
    }

    private func drawGuidance(in ctx: CGContext) {
        let mainText = "ドラッグして範囲選択"
        let subText = "ESC でキャンセル"

        let mainAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor(white: 1, alpha: 0.7)
        ]

        let main = NSAttributedString(string: mainText, attributes: mainAttrs)
        let sub = NSAttributedString(string: subText, attributes: subAttrs)
        let mainSize = main.size()
        let subSize = sub.size()

        let padding: CGFloat = 20
        let spacing: CGFloat = 8
        let boxWidth = max(mainSize.width, subSize.width) + padding * 2
        let boxHeight = mainSize.height + spacing + subSize.height + padding * 2

        let box = NSRect(
            x: (bounds.width - boxWidth) / 2,
            y: (bounds.height - boxHeight) / 2,
            width: boxWidth,
            height: boxHeight
        )

        ctx.setFillColor(NSColor(white: 0, alpha: 0.55).cgColor)
        let roundedPath = CGPath(roundedRect: box, cornerWidth: 10, cornerHeight: 10, transform: nil)
        ctx.addPath(roundedPath)
        ctx.fillPath()

        main.draw(at: NSPoint(
            x: box.midX - mainSize.width / 2,
            y: box.minY + padding
        ))
        sub.draw(at: NSPoint(
            x: box.midX - subSize.width / 2,
            y: box.minY + padding + mainSize.height + spacing
        ))
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
        currentRect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if let rect = currentRect, rect.width > 2, rect.height > 2 {
            onSelect?(rect)
        } else {
            onCancel?()
        }
        startPoint = nil
        currentRect = nil
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        }
    }
}

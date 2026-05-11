import Cocoa

// グラスモーフィズム用カラー
private enum Glass {
    static let bg1 = NSColor(red: 8/255, green: 8/255, blue: 20/255, alpha: 1)
    static let bg2 = NSColor(red: 15/255, green: 15/255, blue: 40/255, alpha: 1)
    static let cardBg = NSColor(white: 1, alpha: 0.07)
    static let cardBorder = NSColor(white: 1, alpha: 0.15)
    static let accent = NSColor(red: 100/255, green: 140/255, blue: 255/255, alpha: 1)
    static let accentGlow = NSColor(red: 80/255, green: 120/255, blue: 255/255, alpha: 0.3)
    static let headerBg = NSColor(white: 1, alpha: 0.05)
    static let headerBorder = NSColor(white: 1, alpha: 0.1)
    static let dropBorder = NSColor(red: 100/255, green: 140/255, blue: 255/255, alpha: 0.35)
    static let textPrimary = NSColor(white: 1, alpha: 0.9)
    static let textSecondary = NSColor(white: 1, alpha: 0.4)
}

class PanelViewController: NSViewController {

    private let store = ImageStore.shared
    private var scrollView: NSScrollView!
    private var stackView: NSStackView!
    private var countLabel: NSTextField!

    override func loadView() {
        let baseView = DropReceivingView(frame: NSRect(x: 0, y: 0, width: 300, height: 600))
        baseView.wantsLayer = true
        baseView.onDrop = { [weak self] image in
            self?.store.add(image: image)
        }
        view = baseView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // グラデーション背景
        let gradLayer = CAGradientLayer()
        gradLayer.frame = view.bounds
        gradLayer.colors = [Glass.bg1.cgColor, Glass.bg2.cgColor]
        gradLayer.startPoint = CGPoint(x: 0, y: 1)
        gradLayer.endPoint = CGPoint(x: 1, y: 0)
        gradLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer?.insertSublayer(gradLayer, at: 0)

        buildUI()
        reloadImages()

        store.onChange = { [weak self] in
            DispatchQueue.main.async { self?.reloadImages() }
        }
    }

    private func buildUI() {
        // ヘッダー
        let headerBg = NSView()
        headerBg.wantsLayer = true
        headerBg.layer?.backgroundColor = Glass.headerBg.cgColor

        let headerBorder = NSView()
        headerBorder.wantsLayer = true
        headerBorder.layer?.backgroundColor = Glass.headerBorder.cgColor

        let title = NSTextField(labelWithString: "10Shot")
        title.font = .boldSystemFont(ofSize: 17)
        title.textColor = Glass.textPrimary

        countLabel = NSTextField(labelWithString: "(0/10)")
        countLabel.font = .systemFont(ofSize: 11)
        countLabel.textColor = Glass.textSecondary

        let ssBtn = makeGlassButton(title: "SS")
        ssBtn.action = #selector(takeScreenshot)
        ssBtn.target = self
        ssBtn.toolTip = "範囲選択スクリーンショット"

        let clearBtn = makeGlassButton(title: "Clear")
        clearBtn.action = #selector(clearAll)
        clearBtn.target = self

        let quitBtn = makeGlassButton(title: "Quit")
        quitBtn.action = #selector(quitApp)
        quitBtn.target = self
        quitBtn.toolTip = "Quit 10Shot"

        // 透明度スライダー行
        let sliderRow = NSView()
        sliderRow.wantsLayer = true
        sliderRow.layer?.backgroundColor = Glass.headerBg.cgColor

        let sliderBorder = NSView()
        sliderBorder.wantsLayer = true
        sliderBorder.layer?.backgroundColor = Glass.headerBorder.cgColor

        let opacityIcon = NSTextField(labelWithString: "◑")
        opacityIcon.font = .systemFont(ofSize: 11)
        opacityIcon.textColor = Glass.textSecondary

        let slider = NSSlider(value: 0.92, minValue: 0.2, maxValue: 1.0,
                              target: self, action: #selector(opacityChanged(_:)))
        slider.sliderType = .linear
        slider.isContinuous = true
        slider.translatesAutoresizingMaskIntoConstraints = false

        // ドロップゾーン
        let dropZone = GlassBorderView()
        let dropLabel = NSTextField(labelWithString: "Drop images here")
        dropLabel.font = .systemFont(ofSize: 12)
        dropLabel.textColor = Glass.textSecondary
        dropLabel.alignment = .center

        // スクロール
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay

        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 12
        stackView.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        scrollView.documentView = stackView

        for v: NSView in [headerBg, headerBorder, title, countLabel,
                          ssBtn, clearBtn, quitBtn, sliderRow, sliderBorder, opacityIcon, slider,
                          dropZone, dropLabel, scrollView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }

        NSLayoutConstraint.activate([
            headerBg.topAnchor.constraint(equalTo: view.topAnchor),
            headerBg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBg.heightAnchor.constraint(equalToConstant: 46),

            headerBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBorder.bottomAnchor.constraint(equalTo: headerBg.bottomAnchor),
            headerBorder.heightAnchor.constraint(equalToConstant: 0.5),

            title.leadingAnchor.constraint(equalTo: headerBg.leadingAnchor, constant: 14),
            title.centerYAnchor.constraint(equalTo: headerBg.centerYAnchor),

            countLabel.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: 6),
            countLabel.centerYAnchor.constraint(equalTo: headerBg.centerYAnchor),

            quitBtn.trailingAnchor.constraint(equalTo: headerBg.trailingAnchor, constant: -10),
            quitBtn.centerYAnchor.constraint(equalTo: headerBg.centerYAnchor),
            clearBtn.trailingAnchor.constraint(equalTo: quitBtn.leadingAnchor, constant: -6),
            clearBtn.centerYAnchor.constraint(equalTo: headerBg.centerYAnchor),
            ssBtn.trailingAnchor.constraint(equalTo: clearBtn.leadingAnchor, constant: -6),
            ssBtn.centerYAnchor.constraint(equalTo: headerBg.centerYAnchor),


            // スライダー行
            sliderRow.topAnchor.constraint(equalTo: headerBg.bottomAnchor),
            sliderRow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sliderRow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sliderRow.heightAnchor.constraint(equalToConstant: 28),

            sliderBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sliderBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sliderBorder.bottomAnchor.constraint(equalTo: sliderRow.bottomAnchor),
            sliderBorder.heightAnchor.constraint(equalToConstant: 0.5),

            opacityIcon.leadingAnchor.constraint(equalTo: sliderRow.leadingAnchor, constant: 12),
            opacityIcon.centerYAnchor.constraint(equalTo: sliderRow.centerYAnchor),

            slider.leadingAnchor.constraint(equalTo: opacityIcon.trailingAnchor, constant: 8),
            slider.trailingAnchor.constraint(equalTo: sliderRow.trailingAnchor, constant: -12),
            slider.centerYAnchor.constraint(equalTo: sliderRow.centerYAnchor),

            dropZone.topAnchor.constraint(equalTo: sliderRow.bottomAnchor, constant: 10),
            dropZone.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            dropZone.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            dropZone.heightAnchor.constraint(equalToConstant: 38),

            dropLabel.centerXAnchor.constraint(equalTo: dropZone.centerXAnchor),
            dropLabel.centerYAnchor.constraint(equalTo: dropZone.centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: dropZone.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
        ])
    }

    private func makeGlassButton(title: String) -> NSButton {
        let btn = NSButton(title: title, target: nil, action: nil)
        btn.bezelStyle = .rounded
        btn.font = .systemFont(ofSize: 10, weight: .medium)
        return btn
    }

    private func makePhotoCard(image: NSImage, index: Int) -> NSView {
        // グラスカード
        let card = GlassCardView()
        card.translatesAutoresizingMaskIntoConstraints = false

        let imgView = DraggableImageView()
        imgView.image = image
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.onClicked = { [weak self] in
            self?.showPreview(image: image)
        }

        let copyBtn = NSButton(title: "Copy", target: self, action: #selector(copyImage(_:)))
        copyBtn.bezelStyle = .rounded
        copyBtn.font = .systemFont(ofSize: 10)
        copyBtn.tag = index
        copyBtn.translatesAutoresizingMaskIntoConstraints = false

        let removeBtn = NSButton(title: "✕", target: self, action: #selector(removeImage(_:)))
        removeBtn.bezelStyle = .circular
        removeBtn.font = .systemFont(ofSize: 9, weight: .bold)
        removeBtn.tag = index
        removeBtn.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(imgView)
        card.addSubview(copyBtn)
        card.addSubview(removeBtn)

        NSLayoutConstraint.activate([
            imgView.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            imgView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            imgView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            imgView.heightAnchor.constraint(equalToConstant: 140),

            copyBtn.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 6),
            copyBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            copyBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),

            removeBtn.centerYAnchor.constraint(equalTo: copyBtn.centerYAnchor),
            removeBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            removeBtn.widthAnchor.constraint(equalToConstant: 22),
            removeBtn.heightAnchor.constraint(equalToConstant: 22),
        ])

        return card
    }

    func reloadImages() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        countLabel.stringValue = "(\(store.images.count)/\(store.maxImages))"

        if store.images.isEmpty {
            let empty = NSTextField(labelWithString: "No images yet")
            empty.textColor = Glass.textSecondary
            empty.font = .systemFont(ofSize: 13)
            empty.alignment = .center
            stackView.addArrangedSubview(empty)
        }

        for i in stride(from: store.images.count - 1, through: 0, by: -1) {
            guard let img = store.nsImage(at: i) else { continue }
            let card = makePhotoCard(image: img, index: i)
            stackView.addArrangedSubview(card)
            card.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -20).isActive = true
        }
    }

    @objc private func copyImage(_ sender: NSButton) {
        guard let img = store.nsImage(at: sender.tag) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([img])
        sender.title = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { sender.title = "Copy" }
    }

    @objc private func removeImage(_ sender: NSButton) {
        store.remove(at: sender.tag)
    }

    @objc private func clearAll() {
        store.clear()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private var previewWindow: ImagePreviewWindow?

    private func showPreview(image: NSImage) {
        previewWindow?.orderOut(nil)
        previewWindow = nil
        let w = ImagePreviewWindow(image: image)
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
        previewWindow = w
    }

    @objc private func opacityChanged(_ sender: NSSlider) {
        view.window?.alphaValue = CGFloat(sender.doubleValue)
    }

    @objc private func takeScreenshot() {
        view.window?.orderOut(nil)
        ScreenshotCapture.shared.captureRegion { [weak self] image in
            self?.view.window?.orderFrontRegardless()
            if let image {
                self?.store.add(image: image)
            }
        }
    }
}

// グラスカード
class GlassCardView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = Glass.cardBg.cgColor
        layer?.cornerRadius = 12
        layer?.borderColor = Glass.cardBorder.cgColor
        layer?.borderWidth = 0.5
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // 上部に薄いグロー
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let glowRect = NSRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1)
        ctx.setFillColor(NSColor(white: 1, alpha: 0.1).cgColor)
        ctx.fill(glowRect)
    }
}

// ドロップゾーンのボーダー
class GlassBorderView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.cornerRadius = 8
        layer?.borderColor = Glass.dropBorder.cgColor
        layer?.borderWidth = 1
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }
}

import Cocoa

/// コルクボードのテクスチャを描画するビュー
class CorkTextureView: DropReceivingView {

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // ベースのコルク色
        let baseColor = NSColor(red: 192/255, green: 150/255, blue: 105/255, alpha: 1)
        ctx.setFillColor(baseColor.cgColor)
        ctx.fill(bounds)

        // コルクの粒状テクスチャ（ランダムなドットでリアル感）
        // シード固定で毎回同じパターンにする
        srand48(42)
        let dotCount = Int(bounds.width * bounds.height / 8)
        for _ in 0..<dotCount {
            let x = CGFloat(drand48()) * bounds.width
            let y = CGFloat(drand48()) * bounds.height
            let size = CGFloat(drand48()) * 3 + 0.5
            let brightness = CGFloat(drand48()) * 0.15
            let isLight = drand48() > 0.5

            if isLight {
                ctx.setFillColor(NSColor(white: 1, alpha: brightness).cgColor)
            } else {
                ctx.setFillColor(NSColor(red: 0.4, green: 0.25, blue: 0.1, alpha: brightness).cgColor)
            }
            ctx.fillEllipse(in: NSRect(x: x, y: y, width: size, height: size))
        }

        // 大きめの繊維模様
        srand48(99)
        for _ in 0..<(dotCount / 15) {
            let x = CGFloat(drand48()) * bounds.width
            let y = CGFloat(drand48()) * bounds.height
            let w = CGFloat(drand48()) * 8 + 2
            let h = CGFloat(drand48()) * 2 + 0.5
            let alpha = CGFloat(drand48()) * 0.08
            ctx.setFillColor(NSColor(red: 0.35, green: 0.2, blue: 0.05, alpha: alpha).cgColor)

            ctx.saveGState()
            let angle = CGFloat(drand48()) * .pi
            ctx.translateBy(x: x, y: y)
            ctx.rotate(by: angle)
            ctx.fillEllipse(in: NSRect(x: -w/2, y: -h/2, width: w, height: h))
            ctx.restoreGState()
        }
    }
}

/// 木枠を描画するビュー
class WoodFrameView: NSView {

    enum Edge {
        case left, right, top, bottom
    }

    var edge: Edge = .left

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // 木枠のベース色
        let darkWood = NSColor(red: 101/255, green: 62/255, blue: 28/255, alpha: 1)
        let midWood = NSColor(red: 139/255, green: 90/255, blue: 43/255, alpha: 1)
        let lightWood = NSColor(red: 170/255, green: 120/255, blue: 60/255, alpha: 1)

        // グラデーション（立体感）
        let colors: [CGColor]
        let startPoint: CGPoint
        let endPoint: CGPoint

        switch edge {
        case .left:
            colors = [lightWood.cgColor, midWood.cgColor, darkWood.cgColor]
            startPoint = CGPoint(x: 0, y: 0)
            endPoint = CGPoint(x: bounds.width, y: 0)
        case .right:
            colors = [darkWood.cgColor, midWood.cgColor, lightWood.cgColor]
            startPoint = CGPoint(x: 0, y: 0)
            endPoint = CGPoint(x: bounds.width, y: 0)
        case .top:
            colors = [lightWood.cgColor, midWood.cgColor, darkWood.cgColor]
            startPoint = CGPoint(x: 0, y: bounds.height)
            endPoint = CGPoint(x: 0, y: 0)
        case .bottom:
            colors = [darkWood.cgColor, midWood.cgColor, lightWood.cgColor]
            startPoint = CGPoint(x: 0, y: bounds.height)
            endPoint = CGPoint(x: 0, y: 0)
        }

        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors as CFArray,
                                  locations: [0, 0.5, 1])!
        ctx.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])

        // 木目の線
        srand48(Int(edge == .left || edge == .right ? 77 : 88))
        let isVertical = (edge == .left || edge == .right)
        let lineCount = isVertical ? Int(bounds.height / 4) : Int(bounds.width / 4)

        for _ in 0..<lineCount {
            let pos = CGFloat(drand48()) * (isVertical ? bounds.height : bounds.width)
            let alpha = CGFloat(drand48()) * 0.15 + 0.02
            ctx.setStrokeColor(NSColor(red: 0.3, green: 0.15, blue: 0.0, alpha: alpha).cgColor)
            ctx.setLineWidth(CGFloat(drand48()) * 0.8 + 0.2)

            if isVertical {
                ctx.move(to: CGPoint(x: 0, y: pos))
                ctx.addLine(to: CGPoint(x: bounds.width, y: pos))
            } else {
                ctx.move(to: CGPoint(x: pos, y: 0))
                ctx.addLine(to: CGPoint(x: pos, y: bounds.height))
            }
            ctx.strokePath()
        }

        // 内側に影（コルクボードとの境目）
        let shadowAlpha: CGFloat = 0.3
        let clearCG = NSColor.clear.cgColor
        let darkCG = NSColor(white: 0, alpha: shadowAlpha).cgColor
        let cs = CGColorSpaceCreateDeviceRGB()

        switch edge {
        case .left:
            let shadowGrad = CGGradient(colorsSpace: cs,
                colors: [clearCG, darkCG] as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(shadowGrad,
                start: CGPoint(x: 0, y: 0), end: CGPoint(x: bounds.width, y: 0), options: [])
        case .right:
            let shadowGrad = CGGradient(colorsSpace: cs,
                colors: [darkCG, clearCG] as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(shadowGrad,
                start: CGPoint(x: 0, y: 0), end: CGPoint(x: bounds.width, y: 0), options: [])
        case .top:
            let shadowGrad = CGGradient(colorsSpace: cs,
                colors: [darkCG, clearCG] as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(shadowGrad,
                start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: bounds.height), options: [])
        case .bottom:
            let shadowGrad = CGGradient(colorsSpace: cs,
                colors: [clearCG, darkCG] as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(shadowGrad,
                start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: bounds.height), options: [])
        }
    }
}

/// マスキングテープ風の留め具を描画
class TapeView: NSView {

    var tapeColor: NSColor = NSColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 0.75)

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let rect = bounds.insetBy(dx: 0, dy: 1)

        // テープの影
        ctx.setShadow(offset: CGSize(width: 0, height: -0.5), blur: 1,
                      color: NSColor.black.withAlphaComponent(0.2).cgColor)

        // テープ本体
        ctx.setFillColor(tapeColor.cgColor)
        let path = NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1)
        path.fill()

        // テープの半透明感
        ctx.setShadow(offset: .zero, blur: 0)
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.1).cgColor)
        let highlightRect = NSRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2)
        ctx.fill(highlightRect)
    }
}

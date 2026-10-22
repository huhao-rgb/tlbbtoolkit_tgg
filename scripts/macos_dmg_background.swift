// 生成 DMG 安装窗口背景图（天工阁 · macOS 拖拽安装界面）。
//
// 用法：swift scripts/macos_dmg_background.swift <输出目录>
// 产出：background.png（780×546）
// 注意：不要在同目录生成 background@2x.png —— dmgbuild 会自动把 @2x 当作整张背景，
// 而 Finder 不做 HiDPI 缩放，结果会大一倍。
//
// 只依赖 macOS 自带的 AppKit/CoreGraphics，不引入第三方库。
import AppKit
import CoreGraphics
import Foundation

let baseWidth: CGFloat = 780
// 背景高度取窗口高度（含标题栏/状态栏），Finder 从左上角 1:1 绘制并裁掉多余部分，
// 这样窗口内容区变大时也不会露出白色底。
let baseHeight: CGFloat = 546

/// 一像素虚线网格 + 顶部金色光晕，纯装饰。
func drawBackdrop(_ ctx: CGContext, scale: CGFloat) {
    let w = baseWidth * scale
    let h = baseHeight * scale

    // 底色：斜向线性渐变
    // 只用两个色标，避免中间停靠点产生可见的横向分层。
    let colors = [
        NSColor(srgbRed: 0x15 / 255, green: 0x14 / 255, blue: 0x1a / 255, alpha: 1).cgColor,
        NSColor(srgbRed: 0x0b / 255, green: 0x0b / 255, blue: 0x0f / 255, alpha: 1).cgColor,
    ] as CFArray
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: h),
        end: CGPoint(x: w, y: 0),
        options: []
    )

    // 顶部金色光晕
    let glow = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(srgbRed: 0.85, green: 0.73, blue: 0.42, alpha: 0.16).cgColor,
            NSColor(srgbRed: 0.85, green: 0.73, blue: 0.42, alpha: 0).cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!
    let glowCenter = CGPoint(x: w * 0.5, y: h + baseHeight * 0.1 * scale)
    ctx.drawRadialGradient(
        glow,
        startCenter: glowCenter,
        startRadius: 0,
        endCenter: glowCenter,
        endRadius: 560 * scale,
        options: []
    )

    // 点阵：越靠近中心越明显（模拟 CSS mask）
    let spacing = 26 * scale
    let dotRadius = 1.2 * scale
    let maskCenter = CGPoint(x: w * 0.5, y: h - 158 * scale)
    let maskRadiusX = 320 * scale
    let maskRadiusY = 190 * scale

    ctx.setFillColor(NSColor(srgbRed: 0.85, green: 0.73, blue: 0.42, alpha: 1).cgColor)
    var y = spacing * 0.5
    while y < h {
        var x = spacing * 0.5
        while x < w {
            let nx = (x - maskCenter.x) / maskRadiusX
            let ny = (y - maskCenter.y) / maskRadiusY
            let distance = sqrt(nx * nx + ny * ny)
            if distance < 1 {
                let alpha = 0.14 * (1 - distance)
                ctx.setAlpha(alpha)
                ctx.fillEllipse(
                    in: CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                )
            }
            x += spacing
        }
        y += spacing
    }
    ctx.setAlpha(1)
}

func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

/// 圆角方形印章（与 Windows 安装器的视觉一致）。
func drawSeal(_ ctx: CGContext, center: CGPoint, size: CGFloat, scale: CGFloat) {
    let rect = CGRect(
        x: center.x - size / 2,
        y: center.y - size / 2,
        width: size,
        height: size
    )
    let path = roundedRectPath(rect, radius: size * 0.24)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(srgbRed: 0xE8 / 255, green: 0xCF / 255, blue: 0x96 / 255, alpha: 1).cgColor,
            NSColor(srgbRed: 0xB9 / 255, green: 0x8A / 255, blue: 0x3D / 255, alpha: 1).cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.minX, y: rect.maxY),
        end: CGPoint(x: rect.maxX, y: rect.minY),
        options: []
    )
    // 高光
    let highlight = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(white: 1, alpha: 0.32).cgColor,
            NSColor(white: 1, alpha: 0).cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        highlight,
        start: CGPoint(x: rect.minX, y: rect.maxY),
        end: CGPoint(x: rect.midX, y: rect.midY),
        options: []
    )
    ctx.restoreGState()

    drawText(
        "工",
        ctx: ctx,
        center: center,
        font: NSFont(name: "PingFangSC-Semibold", size: 30 * scale)
            ?? NSFont.systemFont(ofSize: 30 * scale, weight: .bold),
        color: NSColor(srgbRed: 0x1a / 255, green: 0x14 / 255, blue: 0x0a / 255, alpha: 1),
        kern: 0
    )
}

func drawText(
    _ text: String,
    ctx: CGContext,
    center: CGPoint,
    font: NSFont,
    color: NSColor,
    kern: CGFloat
) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .kern: kern,
    ]
    let attributed = NSAttributedString(string: text, attributes: attributes)
    let size = attributed.size()
    // CoreGraphics 的原点在左下，AppKit 绘制用基线坐标；这里直接算基线位置。
    let origin = CGPoint(
        x: center.x - size.width / 2,
        y: center.y - size.height / 2 + (font.ascender - abs(font.descender)) / 2
    )
    NSGraphicsContext.saveGraphicsState()
    attributed.draw(at: origin)
    NSGraphicsContext.restoreGraphicsState()
}

/// 虚线弧 + 箭头
func drawArrow(_ ctx: CGContext, scale: CGFloat) {
    // 两个图标中心分别在 x=209 / 649，箭头画在两者之间的中点 429。
    let start = CGPoint(x: 340 * scale, y: 272 * scale)
    let control = CGPoint(x: 431 * scale, y: 228 * scale)
    let end = CGPoint(x: 522 * scale, y: 248 * scale)

    ctx.setStrokeColor(NSColor(srgbRed: 0.85, green: 0.73, blue: 0.42, alpha: 1).cgColor)
    ctx.setLineWidth(3 * scale)
    ctx.setLineCap(.round)
    ctx.setLineDash(phase: 0, lengths: [1 * scale, 9 * scale])

    let path = CGMutablePath()
    path.move(to: start)
    path.addQuadCurve(to: end, control: control)
    ctx.addPath(path)
    ctx.strokePath()
    ctx.setLineDash(phase: 0, lengths: [])

    // 箭头：按末端切线方向画两条短线
    let tangent = CGPoint(x: end.x - control.x, y: end.y - control.y)
    let length = sqrt(tangent.x * tangent.x + tangent.y * tangent.y)
    let ux = tangent.x / length
    let uy = tangent.y / length
    let back: CGFloat = 17 * scale
    let spread: CGFloat = 9 * scale
    let tip = end
    let left = CGPoint(
        x: tip.x - ux * back - uy * spread,
        y: tip.y - uy * back + ux * spread
    )
    let right = CGPoint(
        x: tip.x - ux * back + uy * spread,
        y: tip.y - uy * back - ux * spread
    )
    ctx.setStrokeColor(NSColor(srgbRed: 0.91, green: 0.81, blue: 0.59, alpha: 1).cgColor)
    ctx.setLineWidth(3 * scale)
    ctx.setLineJoin(.round)
    ctx.move(to: left)
    ctx.addLine(to: tip)
    ctx.addLine(to: right)
    ctx.strokePath()
}

func render(scale: CGFloat) -> Data {
    let pixelWidth = Int(baseWidth * scale)
    let pixelHeight = Int(baseHeight * scale)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil,
        width: pixelWidth,
        height: pixelHeight,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    ctx.scaleBy(x: scale, y: scale)

    let graphics = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.current = graphics

    drawBackdrop(ctx, scale: scale)

    // 海报头：印章 + 标题 + 副标题（窗口坐标系用左下原点，这里按设计稿顶部偏移换算）
    let sealCenter = CGPoint(x: baseWidth / 2, y: baseHeight - 26 - 29)
    drawSeal(ctx, center: sealCenter, size: 58, scale: scale)

    drawText(
        "天 工 阁",
        ctx: ctx,
        center: CGPoint(x: baseWidth / 2, y: baseHeight - 106),
        font: NSFont(name: "PingFangSC-Semibold", size: 22 * scale)
            ?? NSFont.systemFont(ofSize: 22 * scale, weight: .semibold),
        color: NSColor(srgbRed: 0xE8 / 255, green: 0xCF / 255, blue: 0x96 / 255, alpha: 1),
        kern: 2 * scale
    )

    drawText(
        "TIANLONG NOSTALGIA TOOLKIT",
        ctx: ctx,
        center: CGPoint(x: baseWidth / 2, y: baseHeight - 130),
        font: NSFont(name: "HelveticaNeue-Medium", size: 11 * scale)
            ?? NSFont.systemFont(ofSize: 11 * scale, weight: .medium),
        color: NSColor(srgbRed: 0x8A / 255, green: 0x85 / 255, blue: 0x78 / 255, alpha: 1),
        kern: 1.6 * scale
    )

    drawArrow(ctx, scale: scale)

    drawText(
        "拖 拽 安 装",
        ctx: ctx,
        center: CGPoint(x: 429, y: baseHeight - 330),
        font: NSFont(name: "PingFangSC-Medium", size: 12 * scale)
            ?? NSFont.systemFont(ofSize: 12 * scale, weight: .medium),
        color: NSColor(srgbRed: 0xD9 / 255, green: 0xB9 / 255, blue: 0x6C / 255, alpha: 1),
        kern: 2 * scale
    )

    // 底部提示：未签名包首次打开需要手动放行（换成图标会和箭头挤在一起）。
    drawText(
        "首次打开如提示「无法验证开发者」",
        ctx: ctx,
        center: CGPoint(x: baseWidth / 2, y: baseHeight - 466),
        font: NSFont(name: "PingFangSC-Regular", size: 10.5 * scale)
            ?? NSFont.systemFont(ofSize: 10.5 * scale),
        color: NSColor(srgbRed: 0x8A / 255, green: 0x85 / 255, blue: 0x78 / 255, alpha: 1),
        kern: 0.5 * scale
    )
    drawText(
        "请到「系统设置 → 隐私与安全性 → 仍要打开」",
        ctx: ctx,
        center: CGPoint(x: baseWidth / 2, y: baseHeight - 482),
        font: NSFont(name: "PingFangSC-Regular", size: 10.5 * scale)
            ?? NSFont.systemFont(ofSize: 10.5 * scale),
        color: NSColor(srgbRed: 0x8A / 255, green: 0x85 / 255, blue: 0x78 / 255, alpha: 1),
        kern: 0.5 * scale
    )

    NSGraphicsContext.current = nil

    let image = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: image)
    rep.size = NSSize(width: baseWidth * scale, height: baseHeight * scale)
    return rep.representation(using: .png, properties: [:])!
}

let args = CommandLine.arguments
let outDir = args.count > 1 ? args[1] : "build/macos/dmg"
try FileManager.default.createDirectory(
    atPath: outDir,
    withIntermediateDirectories: true
)
let out1 = URL(fileURLWithPath: outDir).appendingPathComponent("background.png")
try render(scale: 1).write(to: out1)
print("已生成：\(out1.path)")

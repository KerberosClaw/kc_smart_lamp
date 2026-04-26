// ColorWheelView.swift
// HSV color disc — Apple-style radial picker. Hue around the rim, saturation
// from white center outward.

import SwiftUI

struct ColorWheelView: View {
    @Binding var hue: Double          // 0...360
    @Binding var saturation: Double   // 0...1

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let r = size / 2
            let thumbInset: CGFloat = 14

            ZStack {
                // hue ring
                AngularGradient(
                    gradient: Gradient(colors: [
                        .red, .yellow, .green, .cyan, .blue, .purple, .red
                    ]),
                    center: .center
                )
                .clipShape(Circle())

                // saturation falloff (white at center → transparent at rim)
                RadialGradient(
                    colors: [.white, .white.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: r
                )
                .clipShape(Circle())

                // inner rim shadow + outer accent glow
                Circle()
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    .shadow(color: .black.opacity(0.25), radius: 10, y: 4)

                // thumb
                let pos = thumbPosition(r: r, inset: thumbInset)
                Circle()
                    .fill(currentColor)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    .position(x: r + pos.x, y: r + pos.y)
                    .allowsHitTesting(false)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        update(from: v.location, in: r, inset: thumbInset)
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func thumbPosition(r: CGFloat, inset: CGFloat) -> CGPoint {
        let rad = hue * .pi / 180
        return CGPoint(
            x: cos(rad) * saturation * (r - inset),
            y: sin(rad) * saturation * (r - inset)
        )
    }

    private func update(from p: CGPoint, in r: CGFloat, inset: CGFloat) {
        let dx = p.x - r, dy = p.y - r
        var h = atan2(dy, dx) * 180 / .pi
        if h < 0 { h += 360 }
        let dist = sqrt(dx * dx + dy * dy)
        hue = h
        saturation = min(1, dist / (r - inset))
    }

    private var currentColor: Color {
        let (r, g, b) = HSV.toRGB(hue: hue, saturation: saturation, value: 1)
        return Color(red: r, green: g, blue: b)
    }
}

#Preview {
    ColorWheelView(hue: .constant(28), saturation: .constant(0.55))
        .frame(width: 280, height: 280)
        .background(.black)
}

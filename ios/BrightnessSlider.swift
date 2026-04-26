// BrightnessSlider.swift
// Horizontal brightness slider, 0–100. Drag fills with accent gradient.

import SwiftUI

struct BrightnessSlider: View {
    @Binding var value: Int          // 0...100
    let accent: Color

    private let trackHeight: CGFloat = 36
    private let thumbSize: CGFloat   = 28

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Brightness")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text("\(value)%")
                    .font(.system(size: 15, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }

            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    // track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: trackHeight / 2)
                                .strokeBorder(.white.opacity(0.10), lineWidth: 0.5)
                        )

                    // fill
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.15), accent],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(thumbSize, w * CGFloat(value) / 100))
                        .animation(.linear(duration: 0.08), value: value)

                    // thumb
                    Circle()
                        .fill(.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                        .offset(x: max(0, min(w - thumbSize, w * CGFloat(value) / 100 - thumbSize / 2)))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            let pct = max(0, min(1, v.location.x / w))
                            value = Int(round(pct * 100))
                        }
                )
            }
            .frame(height: trackHeight)
        }
    }
}

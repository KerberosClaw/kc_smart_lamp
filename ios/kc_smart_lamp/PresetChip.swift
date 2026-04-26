// PresetChip.swift + PresetRow.swift (combined)
// Three preset chips (Focus / Warm / Off). Tap → apply directly (skip Apply).

import SwiftUI

struct Preset: Identifiable, Equatable {
    enum Kind: Equatable {
        case off
        case color(hue: Double, saturation: Double, brightness: Int)
    }
    let id: String
    let label: String
    let sub: String
    let kind: Kind
    let swatch: Color   // visible glyph color (for chip glow)

    static let all: [Preset] = [
        Preset(id: "focus",
               label: "Focus", sub: "勿擾",
               kind: .color(hue: 0,  saturation: 0.87, brightness: 60),
               swatch: Color(red: 0.90, green: 0.12, blue: 0.12)),
        Preset(id: "warm",
               label: "Warm",  sub: "夜燈",
               kind: .color(hue: 32, saturation: 0.65, brightness: 35),
               swatch: Color(red: 1.00, green: 0.71, blue: 0.35)),
        Preset(id: "off",
               label: "Off",   sub: "關閉",
               kind: .off,
               swatch: Color(white: 0.32))
    ]
}

struct PresetRow: View {
    @Binding var active: Preset.ID?
    let onPick: (Preset) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Presets")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text("tap 即套用")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.35))
            }
            HStack(spacing: 10) {
                ForEach(Preset.all) { p in
                    PresetChip(preset: p, isActive: active == p.id) {
                        onPick(p)
                    }
                }
            }
        }
    }
}

struct PresetChip: View {
    let preset: Preset
    let isActive: Bool
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                glyph
                Text(preset.label)
                    .font(.system(size: 14, weight: .semibold))
                Text(preset.sub)
                    .font(.system(size: 10.5))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: LampMetrics.chipRadius)
                    .fill(
                        isActive
                        ? AnyShapeStyle(LinearGradient(
                            colors: [preset.swatch.opacity(0.28), preset.swatch.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LampMetrics.chipRadius)
                            .strokeBorder(
                                isActive ? preset.swatch.opacity(0.55) : .white.opacity(0.10),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: isActive ? preset.swatch.opacity(0.35) : .clear, radius: 18)
            )
            .scaleEffect(pressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: pressed)
            .animation(LampMetrics.spring, value: isActive)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }

    @ViewBuilder
    private var glyph: some View {
        switch preset.kind {
        case .off:
            // power glyph
            ZStack {
                Circle()
                    .strokeBorder(.white.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                Capsule()
                    .fill(.white.opacity(0.85))
                    .frame(width: 1.5, height: 10)
                    .offset(y: -4)
            }
        default:
            Circle()
                .fill(preset.swatch)
                .frame(width: 22, height: 22)
                .shadow(color: preset.swatch.opacity(0.7), radius: 7)
        }
    }
}

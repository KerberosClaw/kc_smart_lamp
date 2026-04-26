// LampScreen.swift
// Single-screen main view. All v1 controls live here.

import SwiftUI

struct LampScreen: View {
    @Environment(LampState.self) private var lamp
    @Environment(LampBLEClient.self) private var ble

    @State private var connection: ConnectionState = .scanning
    @State private var activePreset: Preset.ID? = nil
    @State private var autoApplyTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            // base black + dynamic radial tint that follows accent + brightness
            Color.black.ignoresSafeArea()
            RadialGradient(
                colors: [
                    lamp.accentColor.opacity(lamp.power ? (0.10 + Double(lamp.brightness) / 100 * 0.18) : 0),
                    lamp.accentColor.opacity(0.04),
                    .black
                ],
                center: .top,
                startRadius: 0, endRadius: 600
            )
            .ignoresSafeArea()
            .animation(LampMetrics.spring, value: lamp.accentColor)
            .animation(LampMetrics.spring, value: lamp.brightness)
            .animation(LampMetrics.spring, value: lamp.power)

            // dot grid texture (industrial vibe)
            DotGrid()
                .opacity(0.5)
                .mask(
                    RadialGradient(
                        colors: [.black, .clear],
                        center: UnitPoint(x: 0.5, y: 0.3),
                        startRadius: 0, endRadius: 380
                    )
                )

            content
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            // connection pill
            HStack {
                ConnectionPill(state: connection) {
                    if case .failed = connection {
                        Task { await retryConnection() }
                    }
                }
                Spacer()
            }
            .padding(.top, 8)

            // device header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Desk Lamp")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.6)
                        .foregroundStyle(.white.opacity(0.45))
                    Text("kc_smart_lamp")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .kerning(-0.4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(lamp.accentColor.hexString)
                    Text("\(lamp.brightness)%")
                }
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.top, 14)

            // hero color wheel
            ZStack {
                ColorWheelView(
                    hue: Binding(
                        get: { lamp.hue },
                        set: { lamp.hue = $0; activePreset = nil }
                    ),
                    saturation: Binding(
                        get: { lamp.saturation },
                        set: { lamp.saturation = $0; activePreset = nil }
                    )
                )
                .frame(width: 278, height: 278)
                .opacity(lamp.power ? 1.0 : 0.45)
                .animation(LampMetrics.spring, value: lamp.power)

                // central readout
                Circle()
                    .fill(lamp.power ? lamp.accentColor : Color(white: 0.2))
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 2.5))
                    .shadow(color: lamp.accentColor.opacity(lamp.power ? 0.7 : 0), radius: 18)
                    .animation(LampMetrics.spring, value: lamp.power)
                    .animation(LampMetrics.spring, value: lamp.accentColor)
            }
            .padding(.top, 22)
            .padding(.bottom, 18)

            // brightness
            BrightnessSlider(
                value: Binding(
                    get: { lamp.brightness },
                    set: { lamp.brightness = $0; activePreset = nil }
                ),
                accent: lamp.accentColor
            )
            .opacity(lamp.power ? 1 : 0.45)
            .padding(.bottom, LampMetrics.gap)

            // presets
            PresetRow(active: $activePreset) { preset in
                applyPreset(preset)
            }

            Spacer(minLength: 0)

            // power toggle
            PowerToggleRow(
                isOn: Binding(get: { lamp.power }, set: { lamp.power = $0 }),
                accent: lamp.accentColor
            )
        }
        .padding(.horizontal, LampMetrics.pad)
        .padding(.bottom, 24)
        .task {
            await initialConnect()
        }
        // Continuous inputs (wheel / slider) → debounced auto-apply.
        .onChange(of: lamp.hue)        { scheduleAutoApply() }
        .onChange(of: lamp.saturation) { scheduleAutoApply() }
        .onChange(of: lamp.brightness) { scheduleAutoApply() }
        // Power is a discrete action — bypass debounce, fire immediately.
        .onChange(of: lamp.power) {
            autoApplyTask?.cancel()
            Task { try? await ble.write(lamp.payload()) }
        }
    }

    // MARK: - Actions

    /// Continuous inputs (wheel / slider) call this on every change.
    /// Last call within the window wins, so the BLE write only fires once
    /// after the user stops moving.  Power and presets bypass this and
    /// call `ble.write` directly.
    private func scheduleAutoApply(delay: Duration = .milliseconds(220)) {
        autoApplyTask?.cancel()
        autoApplyTask = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            try? await ble.write(lamp.payload())
        }
    }

    private func applyPreset(_ p: Preset) {
        withAnimation(LampMetrics.spring) {
            activePreset = p.id
            switch p.kind {
            case .off:
                lamp.power = false
            case .color(let h, let s, let bri):
                lamp.power = true
                lamp.hue = h
                lamp.saturation = s
                lamp.brightness = bri
            }
        }
        // presets bypass the debounce — fire immediately
        autoApplyTask?.cancel()
        Task { try? await ble.write(lamp.payload()) }
    }

    private func initialConnect() async {
        connection = .scanning
        do {
            let name = try await ble.connect()
            connection = .connected(name: name)
            if let data = try? await ble.read() {
                lamp.adopt(data)
            }
        } catch {
            connection = .failed
        }
    }

    private func retryConnection() async {
        await initialConnect()
    }
}

// MARK: - Background dot grid

private struct DotGrid: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 22
            ctx.opacity = 0.14
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let r = CGRect(x: x, y: y, width: 1, height: 1)
                    ctx.fill(Path(ellipseIn: r), with: .color(.white))
                    x += step
                }
                y += step
            }
        }
        .ignoresSafeArea()
    }
}

// Hex string helper for the readout
extension Color {
    var hexString: String {
        // SwiftUI Color → UIColor → components. iOS-only.
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int((r * 255).rounded()),
                      Int((g * 255).rounded()),
                      Int((b * 255).rounded()))
        #else
        return "—"
        #endif
    }
}

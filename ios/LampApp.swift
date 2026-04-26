// LampApp.swift
// kc_smart_lamp iOS App entry + shared model.
//
// Architecture: thin client (ADR 0003).
// All "intelligence" runs on the Mac host — this app only reads/writes the
// 5-byte LAMP_STATE characteristic.

import SwiftUI

@main
struct LampApp: App {
    @State private var lamp = LampState()
    @State private var ble = LampBLEClient()

    var body: some Scene {
        WindowGroup {
            LampScreen()
                .environment(lamp)
                .environment(ble)
                .preferredColorScheme(.dark)         // dark only
                .statusBarHidden(false)
                .persistentSystemOverlays(.visible)
        }
    }
}

// MARK: - LampState (mirrors the 5-byte LAMP_STATE)

@Observable
final class LampState {
    /// Power byte (0 = off, 1 = on)
    var power: Bool = true
    /// HSV — internal authoring representation. RGB is derived for write.
    var hue: Double = 28           // 0...360
    var saturation: Double = 0.55  // 0...1
    /// Brightness percent (0–100), the 5th byte
    var brightness: Int = 60

    /// What we'd actually write to the lamp right now.
    var rgb: (r: UInt8, g: UInt8, b: UInt8) {
        let (r, g, b) = HSV.toRGB(hue: hue, saturation: saturation, value: 1.0)
        return (UInt8(r * 255), UInt8(g * 255), UInt8(b * 255))
    }

    /// Color used everywhere as the dynamic accent.
    var accentColor: Color {
        guard power else { return Color(white: 0.45) }
        let (r, g, b) = HSV.toRGB(hue: hue, saturation: saturation, value: 1.0)
        return Color(red: r, green: g, blue: b)
    }

    /// Pack into the 5-byte payload defined by gatt_spec.md.
    func payload() -> Data {
        var data = Data(count: 5)
        data[0] = power ? 1 : 0
        data[1] = rgb.r
        data[2] = rgb.g
        data[3] = rgb.b
        data[4] = UInt8(min(100, max(0, brightness)))
        return data
    }

    /// Unpack a 5-byte read.
    func adopt(_ data: Data) {
        guard data.count == 5 else { return }
        power = data[0] == 1
        let r = Double(data[1]) / 255
        let g = Double(data[2]) / 255
        let b = Double(data[3]) / 255
        let hsv = HSV.fromRGB(r: r, g: g, b: b)
        hue = hsv.h
        saturation = hsv.s
        brightness = Int(data[4])
    }
}

// MARK: - Connection state

enum ConnectionState: Equatable {
    case scanning
    case connected(name: String)
    case failed
    case disconnected(retry: Int)         // mid-session, auto-retrying
}

// MARK: - HSV math

enum HSV {
    static func toRGB(hue h: Double, saturation s: Double, value v: Double)
        -> (r: Double, g: Double, b: Double)
    {
        let c = v * s
        let x = c * (1 - abs(((h / 60).truncatingRemainder(dividingBy: 2)) - 1))
        let m = v - c
        let (r1, g1, b1): (Double, Double, Double)
        switch h {
        case   0..< 60: (r1, g1, b1) = (c, x, 0)
        case  60..<120: (r1, g1, b1) = (x, c, 0)
        case 120..<180: (r1, g1, b1) = (0, c, x)
        case 180..<240: (r1, g1, b1) = (0, x, c)
        case 240..<300: (r1, g1, b1) = (x, 0, c)
        default:        (r1, g1, b1) = (c, 0, x)
        }
        return (r1 + m, g1 + m, b1 + m)
    }

    static func fromRGB(r: Double, g: Double, b: Double)
        -> (h: Double, s: Double, v: Double)
    {
        let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn
        var h = 0.0
        if d > 0 {
            if mx == r { h = ((g - b) / d).truncatingRemainder(dividingBy: 6) }
            else if mx == g { h = (b - r) / d + 2 }
            else { h = (r - g) / d + 4 }
            h *= 60
            if h < 0 { h += 360 }
        }
        return (h, mx == 0 ? 0 : d / mx, mx)
    }
}

// MARK: - Design tokens

enum LampMetrics {
    static let cardRadius: CGFloat   = 26
    static let buttonRadius: CGFloat = 18
    static let chipRadius: CGFloat   = 14

    static let pad: CGFloat       = 20
    static let gap: CGFloat       = 16
    static let sectionGap: CGFloat = 22

    /// House spring — smooth, never bouncy.
    static let spring: Animation = .spring(response: 0.4, dampingFraction: 0.75)
}

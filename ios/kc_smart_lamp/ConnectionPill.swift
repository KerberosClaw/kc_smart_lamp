// ConnectionPill.swift
// Top-left dot + label showing BLE connection state.

import SwiftUI

struct ConnectionPill: View {
    let state: ConnectionState
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            StatusDot(color: dotColor, pulse: pulses)
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                Text("·")
                    .foregroundStyle(.white.opacity(0.55))
                Text(detail)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(.vertical, 9)
        .padding(.leading, 12)
        .padding(.trailing, 14)
        .background(
            Capsule()
                .fill(.white.opacity(0.05))
                .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 0.5))
                .background(.ultraThinMaterial, in: Capsule())
        )
        .onTapGesture {
            if isRetryable { onTap() }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var dotColor: Color {
        switch state {
        case .scanning:           return Color(white: 0.6)
        case .connected:          return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .failed:             return Color(red: 1.0,  green: 0.23, blue: 0.19)
        case .disconnected:       return Color(red: 1.0,  green: 0.62, blue: 0.04)
        }
    }
    private var pulses: Bool {
        switch state {
        case .scanning, .disconnected: return true
        default: return false
        }
    }
    private var label: String {
        switch state {
        case .scanning:    return "Scanning"
        case .connected:   return "Connected"
        case .failed:      return "Failed"
        case .disconnected: return "Reconnecting"
        }
    }
    private var detail: String {
        switch state {
        case .scanning:                return "搜尋附近裝置…"
        case .connected(let n):        return n
        case .failed:                  return "點擊重新連線"
        case .disconnected(let r):     return "自動重試 (\(r)/3)"
        }
    }
    private var isRetryable: Bool {
        if case .failed = state { return true }
        return false
    }
}

private struct StatusDot: View {
    let color: Color
    let pulse: Bool
    @State private var on = true
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: color, radius: 4)
            .opacity(pulse ? (on ? 1 : 0.45) : 1)
            .scaleEffect(pulse ? (on ? 1 : 0.78) : 1)
            .onAppear {
                guard pulse else { return }
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    on = false
                }
            }
    }
}

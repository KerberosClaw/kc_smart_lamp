// PowerToggleRow.swift
// Bottom-of-screen power row. Low-key because Apply already covers the active path.

import SwiftUI

struct PowerToggleRow: View {
    @Binding var isOn: Bool
    let accent: Color

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "power")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isOn ? accent : .white.opacity(0.55))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Power")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Text(isOn ? "燈泡開啟中" : "燈泡已關閉")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(accent)
                .animation(LampMetrics.spring, value: isOn)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: LampMetrics.buttonRadius)
                .fill(.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: LampMetrics.buttonRadius)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

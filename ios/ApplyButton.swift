// ApplyButton.swift
// Primary CTA. Press → scale down → fire write → "Applied" overlay 1.8s.

import SwiftUI

struct ApplyButton: View {
    let accent: Color
    let onApply: () -> Void

    @State private var pressed = false
    @State private var showApplied = false

    var body: some View {
        Button {
            onApply()
            withAnimation(.easeOut(duration: 0.25)) { showApplied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeIn(duration: 0.25)) { showApplied = false }
            }
        } label: {
            ZStack {
                Text("APPLY")
                    .tracking(6)
                    .opacity(showApplied ? 0 : 1)
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                    Text("Applied")
                        .tracking(0.5)
                }
                .opacity(showApplied ? 1 : 0)
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: LampMetrics.buttonRadius)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.28), accent.opacity(0.18)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LampMetrics.buttonRadius)
                            .strokeBorder(accent.opacity(0.45), lineWidth: 0.5)
                    )
                    .shadow(color: accent.opacity(0.25), radius: 18)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
            )
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}

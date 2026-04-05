import SwiftUI

/// Animated circular gauge that shows test progress and current speed.
struct SpeedGaugeView: View {
    let progress: Double
    let speed: Double?
    let phaseLabel: String?

    @State private var animatedProgress: Double = 0

    private let radius: CGFloat = 100
    private let strokeWidth: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.1), lineWidth: strokeWidth)
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.blue, .purple, .blue]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                if let speed {
                    Text(String(format: "%.1f", speed))
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                } else {
                    Text("--")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("Mbps")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if let phaseLabel {
                    Text(phaseLabel)
                        .font(.caption)
                        .foregroundStyle(.cyan)
                        .padding(.top, 4)
                }
            }
        }
        .frame(width: radius * 2 + strokeWidth * 2, height: radius * 2 + strokeWidth * 2)
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                animatedProgress = newValue
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(speed != nil ? "\(String(format: "%.1f", speed!)) megabits per second" : "Speed test idle")
    }
}
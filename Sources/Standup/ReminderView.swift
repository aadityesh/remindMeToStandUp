import SwiftUI
import AppKit

// MARK: - Window Controller

class ReminderWindowController: NSWindowController {
    init(type: ReminderType) {
        let size = CGSize(width: 380, height: 480)
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let origin = CGPoint(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.midY - size.height / 2
        )

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.alphaValue = 0

        super.init(window: panel)

        panel.contentViewController = NSHostingController(
            rootView: ReminderView(type: type, onDismiss: { [weak self] in
                self?.dismissAnimated()
            })
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 45) { [weak self] in
            self?.dismissAnimated()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        // Fade the window in at the OS level — pairs with the SwiftUI spring inside
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window?.animator().alphaValue = 1
        }
    }

    func dismissAnimated() {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.close()
        })
    }
}

// MARK: - Reminder View

struct ReminderView: View {
    let type: ReminderType
    let onDismiss: () -> Void

    @State private var appeared  = false
    @State private var iconFloat = false
    @State private var iconPulse: CGFloat = 1.0
    @State private var gradientAngle: Double = 0  // drives smooth gradient rotation

    var isStandup: Bool { type == .standup }

    var gradientColors: [Color] {
        isStandup
            ? [Color(hex: "FA7B17"), Color(hex: "F29900"), Color(hex: "FBBC04")]
            : [Color(hex: "34A853"), Color(hex: "00BFA5"), Color(hex: "1A73E8")]
    }

    var icon:    String { isStandup ? "figure.stand" : "drop.fill" }
    var title:   String { isStandup ? "Time to Stand Up!" : "Stay Hydrated!" }
    var message: String {
        isStandup
            ? "You've been sitting a while.\nStretch those legs!"
            : "Your body needs water.\nHave a glass now!"
    }

    // Smooth gradient: rotate start/end points continuously
    var gradientStart: UnitPoint {
        UnitPoint(
            x: 0.5 + 0.5 * cos(gradientAngle * .pi / 180),
            y: 0.5 + 0.5 * sin(gradientAngle * .pi / 180)
        )
    }
    var gradientEnd: UnitPoint {
        UnitPoint(
            x: 0.5 - 0.5 * cos(gradientAngle * .pi / 180),
            y: 0.5 - 0.5 * sin(gradientAngle * .pi / 180)
        )
    }

    var body: some View {
        ZStack {
            // Smoothly rotating gradient — animates because start/end are CGFloat
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: gradientStart,
                        endPoint: gradientEnd
                    )
                )
                .animation(
                    .linear(duration: 8).repeatForever(autoreverses: false),
                    value: gradientAngle
                )

            // Floating colour blobs
            BlobLayer(colors: gradientColors)

            // Glass sheen
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white.opacity(0.06))

            // Content
            VStack(spacing: 26) {
                Spacer()

                // Icon with ripple rings
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.09 - Double(i) * 0.02))
                            .frame(width: CGFloat(84 + i * 28), height: CGFloat(84 + i * 28))
                            .scaleEffect(iconPulse)
                            .animation(
                                .easeInOut(duration: 1.6 + Double(i) * 0.3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                                value: iconPulse
                            )
                    }

                    Circle()
                        .fill(Color.white.opacity(0.24))
                        .frame(width: 86, height: 86)

                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .regular))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors.reversed(),
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(appeared ? 1.0 : 0.5)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.65).delay(0.12),
                            value: appeared
                        )
                }
                .offset(y: iconFloat ? -7 : 7)
                .animation(
                    .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                    value: iconFloat
                )

                // Title + message
                VStack(spacing: 10) {
                    Text(title)
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(.easeOut(duration: 0.45).delay(0.28), value: appeared)

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 17))
                        Text("Got it!")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(gradientColors.first ?? .orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.white)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .scaleEffect(appeared ? 1.0 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.72).delay(0.45), value: appeared)

                Spacer().frame(height: 18)
            }
            .padding(.horizontal, 22)
        }
        .frame(width: 380, height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        // Enter: scale up from 0.88, no bounce overshoot
        .scaleEffect(appeared ? 1.0 : 0.88)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                appeared = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                gradientAngle = 360
            }
            iconPulse = 1.12
            iconFloat = true
        }
    }
}

// MARK: - Background blob layer

struct BlobLayer: View {
    let colors: [Color]
    @State private var animate = false

    private let specs: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (-110, -150, 110, 0.0),
        ( 130, -130,  80, 0.3),
        (-140,  110,  70, 0.6),
        ( 120,  130,  90, 0.9),
        (   0, -175,  55, 1.2),
        (   0,  170, 100, 1.5),
    ]

    var body: some View {
        ZStack {
            ForEach(Array(specs.enumerated()), id: \.offset) { i, s in
                let c = colors[i % colors.count]
                Circle()
                    .fill(RadialGradient(
                        colors: [c.opacity(0.35), .clear],
                        center: .center, startRadius: 0, endRadius: s.2
                    ))
                    .frame(width: s.2 * 2, height: s.2 * 2)
                    .offset(
                        x: animate ? s.0 + (i.isMultiple(of: 2) ? 16 : -16) : s.0,
                        y: animate ? s.1 + (i % 3 == 0 ? 12 : -12) : s.1
                    )
                    .animation(
                        .easeInOut(duration: 3.5 + Double(i) * 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(s.3),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

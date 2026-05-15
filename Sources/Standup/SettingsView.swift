import SwiftUI

struct SettingsView: View {
    @ObservedObject private var manager = TimerManager.shared
    @State private var headerPulse = false
    @State private var appeared = false

    var isExpanded: Bool { manager.isExpanded }
    var showTip: Bool   { manager.showExpandedContent }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(hex: "1A73E8"), Color(hex: "1557B0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 18) {
                // Top bar
                HStack {
                    Button(action: { NSApp.keyWindow?.close() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 22, height: 22)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: { manager.isExpanded.toggle() }) {
                        Image(systemName: isExpanded
                              ? "arrow.down.right.and.arrow.up.left"
                              : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 22, height: 22)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .opacity(appeared ? 1 : 0)

                // Header — fixed size, no scaling during expand
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 68, height: 68)
                            .scaleEffect(headerPulse ? 1.1 : 1.0)
                            .animation(
                                .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                                value: headerPulse
                            )

                        Image(systemName: "figure.stand.line.dotted.figure.stand")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .onAppear { headerPulse = true }

                    Text("Stay Active")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .fixedSize()

                    Text("Your wellness companion")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                // Cards
                VStack(spacing: 10) {
                    ReminderCard(
                        type: .standup,
                        icon: "figure.walk",
                        title: "Stand Up",
                        color: Color(hex: "FA7B17"),
                        value: $manager.standupInterval,
                        countdown: manager.isRunning ? manager.nextStandupIn : nil
                    )

                    ReminderCard(
                        type: .water,
                        icon: "drop.fill",
                        title: "Drink Water",
                        color: Color(hex: "34A853"),
                        value: $manager.waterInterval,
                        countdown: manager.isRunning ? manager.nextWaterIn : nil
                    )
                }
                .padding(.horizontal, 14)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)

                // Wellness tip — appears only after resize is fully done
                if showTip {
                    WellnessTip()
                        .padding(.horizontal, 14)
                        .transition(.opacity)
                }

                // Start / Stop
                StartStopButton(isRunning: manager.isRunning) {
                    manager.isRunning ? manager.stop() : manager.start()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
            }
        }
        // No fixed frame — SwiftUI fills whatever NSPopover currently is
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }
}

// MARK: - Start/Stop button (isolated to prevent layout thrash during colour change)

struct StartStopButton: View {
    let isRunning: Bool
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 18))
                Text(isRunning ? "Stop Reminders" : "Start Reminders")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                ZStack {
                    // Stopped state
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .opacity(isRunning ? 0 : 1)

                    // Running state
                    LinearGradient(
                        colors: [Color(hex: "EA4335"), Color(hex: "C5221F")],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .opacity(isRunning ? 1 : 0)
                }
            )
            .foregroundColor(isRunning ? .white : Color(hex: "1A73E8"))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.22), value: isRunning)
        .animation(.easeOut(duration: 0.1), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}

// MARK: - Reminder Card

struct ReminderCard: View {
    let type: ReminderType
    let icon: String
    let title: String
    let color: Color
    @Binding var value: Double
    let countdown: TimeInterval?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()

                ZStack {
                    if let t = countdown {
                        CountdownBadge(text: TimerManager.shared.formatTime(t))
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal:   .scale(scale: 0.8).combined(with: .opacity)
                            ))
                    } else {
                        Button("Test") { TimerManager.shared.onReminder?(type) }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(color)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.2))
                            .cornerRadius(8)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal:   .scale(scale: 0.8).combined(with: .opacity)
                            ))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: countdown == nil)
            }

            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    Text("Every")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                    Text("\(Int(value)) min")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: value)
                }
                .frame(minWidth: 80, alignment: .leading)

                Slider(value: $value, in: 5...120, step: 5)
                    .accentColor(color)
            }
        }
        .padding(13)
        .background(Color.white.opacity(0.11))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Wellness tip

struct WellnessTip: View {
    private let tips = [
        ("💡", "Standing for just 2 min reduces blood sugar spikes."),
        ("💧", "Aim for 8 glasses of water a day to stay sharp."),
        ("🚶", "A short walk boosts focus for up to 90 minutes."),
        ("🧘", "Deep breathing for 1 min lowers cortisol fast."),
    ]
    @State private var index = Int.random(in: 0..<4)

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(tips[index].0).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 3) {
                Text("Wellness tip")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                Text(tips[index].1)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.09))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

// MARK: - Countdown badge

struct CountdownBadge: View {
    let text: String
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock").font(.system(size: 9))
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.14))
        .cornerRadius(8)
    }
}

// MARK: - Hex colour init

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB,
                  red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}

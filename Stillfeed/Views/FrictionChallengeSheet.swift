import SwiftUI

struct FrictionChallengeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let holdDurationSeconds: Int
    let onUnlocked: () -> Void

    @State private var isHolding = false
    @State private var elapsed: Double = 0
    @State private var timer: Timer?

    private var progress: Double {
        guard holdDurationSeconds > 0 else { return 1 }
        return min(1, elapsed / Double(holdDurationSeconds))
    }

    private var remainingSeconds: Int {
        max(0, Int(ceil(Double(holdDurationSeconds) - elapsed)))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.teal)

                    Text("Take a Breath")
                        .font(.title2.bold())

                    Text("To weaken or disable filters, press and hold the button below continuously for \(holdDurationSeconds) seconds.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                ZStack {
                    Circle()
                        .stroke(Color(.systemFill), lineWidth: 10)
                        .frame(width: 156, height: 156)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.teal,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 156, height: 156)
                        .animation(.linear(duration: 0.05), value: progress)

                    VStack(spacing: 4) {
                        Text(isHolding ? "\(remainingSeconds)s" : "Hold")
                            .font(.title.monospacedDigit().bold())
                        Text(isHolding ? "Keep holding" : "Press & hold")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isHolding {
                                startHold()
                            }
                        }
                        .onEnded { _ in
                            cancelHold()
                        }
                )

                Spacer()

                Button("Keep Filters Active") {
                    cancelHold()
                    dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
            }
            .padding()
            .navigationTitle("Friction Lock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelHold()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                cancelHold()
            }
        }
        .presentationDetents([.medium])
    }

    private func startHold() {
        isHolding = true
        elapsed = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                elapsed += 0.05
                if elapsed >= Double(holdDurationSeconds) {
                    completeHold()
                }
            }
        }
    }

    private func cancelHold() {
        isHolding = false
        timer?.invalidate()
        timer = nil
        elapsed = 0
    }

    private func completeHold() {
        timer?.invalidate()
        timer = nil
        isHolding = false
        onUnlocked()
        dismiss()
    }
}

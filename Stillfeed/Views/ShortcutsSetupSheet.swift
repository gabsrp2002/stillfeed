import SwiftUI

struct ShortcutsSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var copiedTag: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Why a 1-time Shortcuts setup?", systemImage: "bolt.badge.checkmark")
                            .font(.headline)
                            .foregroundStyle(.teal)
                        Text("Apple allows iCloud pop-ups only for regular Shortcuts—not Personal Automations that trigger when you open another app. Setting up a quick App Automation takes ~20 seconds and automatically bounces Instagram or YouTube into Stillfeed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("3-Step Automation Setup") {
                    stepRow(
                        number: "1",
                        title: "Create an App Automation",
                        detail: "Tap \"Open Shortcuts Automation\" below, choose App, pick Instagram (or YouTube), select Is Opened, and choose Run Immediately."
                    )
                    stepRow(
                        number: "2",
                        title: "Pick a Stillfeed Action",
                        detail: "Tap Next → New Blank Automation → search \"Stillfeed\" and choose \"Open Instagram in Stillfeed\" (or \"Open YouTube in Stillfeed\")."
                    )
                    stepRow(
                        number: "3",
                        title: "Or Use a Deep Link URL",
                        detail: "Alternatively, pick the \"Open URLs\" action in Shortcuts and paste one of the deep links below."
                    )
                }

                Section("Deep Links") {
                    deepLinkRow(title: "Instagram", urlString: "stillfeed://instagram")
                    deepLinkRow(title: "YouTube", urlString: "stillfeed://youtube")
                    deepLinkRow(title: "Any IG / YT Link", urlString: "stillfeed://open?url=...")
                }

                Section {
                    Button {
                        if let url = URL(string: "shortcuts://create-automation") {
                            openURL(url)
                        }
                    } label: {
                        Label("Open Shortcuts Automation", systemImage: "arrow.up.forward.app.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.teal)
                }
            }
            .navigationTitle("Redirect Official Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func stepRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.teal, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func deepLinkRow(title: String, urlString: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(urlString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(copiedTag == urlString ? "Copied" : "Copy") {
                UIPasteboard.general.string = urlString
                copiedTag = urlString
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .tint(copiedTag == urlString ? .teal : .secondary)
        }
    }
}

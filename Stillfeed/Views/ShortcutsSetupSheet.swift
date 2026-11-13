import StillfeedCore
import SwiftUI

struct ShortcutsSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(FilterSettingsStore.self) private var store

    @State private var copiedTag: String?

    var body: some View {
        let copy = store.copy

        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(copy.shortcutsWhyTitle, systemImage: "bolt.badge.checkmark")
                            .font(.headline)
                            .foregroundStyle(.teal)
                        Text(copy.shortcutsWhyBody)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section(copy.shortcutsStepsSectionTitle) {
                    stepRow(
                        number: "1",
                        title: copy.shortcutsStep1Title,
                        detail: copy.shortcutsStep1Detail
                    )
                    stepRow(
                        number: "2",
                        title: copy.shortcutsStep2Title,
                        detail: copy.shortcutsStep2Detail
                    )
                    stepRow(
                        number: "3",
                        title: copy.shortcutsStep3Title,
                        detail: copy.shortcutsStep3Detail
                    )
                }

                Section(copy.deepLinksSectionTitle) {
                    deepLinkRow(title: SocialPlatform.instagram.displayName, urlString: "stillfeed://instagram", copy: copy)
                    deepLinkRow(title: SocialPlatform.youtube.displayName, urlString: "stillfeed://youtube", copy: copy)
                    deepLinkRow(title: copy.deepLinkAnyLabel, urlString: "stillfeed://open?url=...", copy: copy)
                }

                Section {
                    Button {
                        if let url = URL(string: "shortcuts://create-automation") {
                            openURL(url)
                        }
                    } label: {
                        Label(copy.openShortcutsAutomationButton, systemImage: "arrow.up.forward.app.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.teal)
                }
            }
            .navigationTitle(copy.shortcutsNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy.doneButton) { dismiss() }
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

    private func deepLinkRow(title: String, urlString: String, copy: AppCopy) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(urlString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(copiedTag == urlString ? copy.copiedButton : copy.copyButton) {
                UIPasteboard.general.string = urlString
                copiedTag = urlString
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .tint(copiedTag == urlString ? .teal : .secondary)
        }
    }
}

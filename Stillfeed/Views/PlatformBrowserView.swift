import StillfeedCore
import SwiftUI

struct PlatformBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FilterSettingsStore.self) private var store

    let platform: SocialPlatform
    var initialURL: URL? = nil
    @State private var controller = WebBrowserController()
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            loadingProgressBar
            ZStack(alignment: .top) {
                PlatformWebView(
                    platform: platform,
                    initialURL: initialURL,
                    config: store.config,
                    controller: controller
                )
                .ignoresSafeArea(.container, edges: .bottom)

                if let notice = controller.noticeMessage {
                    noticeToast(notice)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(item: $controller.externalURL) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
    }

    private var topToolbar: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "house")
                    .font(.body.weight(.semibold))
            }
            .accessibilityLabel("Back to Stillfeed Home")

            Button {
                controller.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.medium))
            }
            .disabled(!controller.canGoBack)

            Button {
                controller.goForward()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
            }
            .disabled(!controller.canGoForward)

            Spacer()

            Button {
                showingSettings = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.teal)
                    Text(platform.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.tertiarySystemFill), in: Capsule())
            }

            Spacer()

            Menu {
                ForEach(platform.quickDestinations) { destination in
                    Button {
                        controller.load(url: destination.url)
                    } label: {
                        Label(destination.title, systemImage: destination.systemImage)
                    }
                }
            } label: {
                Image(systemName: "safari")
                    .font(.body.weight(.medium))
            }
            .accessibilityLabel("Quick Destinations")

            Button {
                controller.reload()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.body.weight(.medium))
            }
            .accessibilityLabel("Reload")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    @ViewBuilder
    private var loadingProgressBar: some View {
        if controller.isLoading && controller.estimatedProgress < 1.0 {
            ProgressView(value: controller.estimatedProgress)
                .progressViewStyle(.linear)
                .tint(.teal)
                .frame(height: 2)
        }
    }

    private func noticeToast(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(.teal)
            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

import SwiftUI
import WebKit

final class BrowserModel: NSObject, ObservableObject {
    let webView: WKWebView
    static let home = "https://www.google.com"

    @Published var address = ""
    @Published var progress: Double = 0
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false

    private var observations: [NSKeyValueObservation] = []

    override init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        super.init()

        observations = [
            webView.observe(\.estimatedProgress) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.progress = wv.estimatedProgress }
            },
            webView.observe(\.isLoading) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.isLoading = wv.isLoading }
            },
            webView.observe(\.canGoBack) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.canGoBack = wv.canGoBack }
            },
            webView.observe(\.canGoForward) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.canGoForward = wv.canGoForward }
            },
            webView.observe(\.url) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.address = wv.url?.absoluteString ?? "" }
            }
        ]
        load(Self.home)
    }

    /// Accepts a URL ("apple.com") or a search ("best pizza near me").
    func load(_ input: String) {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        var url: URL?
        if text.contains(" ") || !text.contains(".") {
            var comps = URLComponents(string: "https://www.google.com/search")!
            comps.queryItems = [URLQueryItem(name: "q", value: text)]
            url = comps.url
        } else if text.hasPrefix("http://") || text.hasPrefix("https://") {
            url = URL(string: text)
        } else {
            url = URL(string: "https://" + text)
        }
        if let url { webView.load(URLRequest(url: url)) }
    }
}

struct WebView: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct BrowserView: View {
    @StateObject private var model = BrowserModel()
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: model.address.hasPrefix("https") && !focused ? "lock.fill" : "magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Search or enter website", text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.webSearch)
                        .submitLabel(.go)
                        .focused($focused)
                        .onSubmit {
                            model.load(text)
                            focused = false
                        }
                    if focused && !text.isEmpty {
                        Button { text = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                if focused {
                    Button("Cancel") {
                        focused = false
                        text = model.address
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            ProgressView(value: model.progress)
                .opacity(model.isLoading ? 1 : 0)

            WebView(webView: model.webView)

            HStack {
                Button { model.webView.goBack() } label: { Image(systemName: "chevron.backward") }
                    .disabled(!model.canGoBack)
                Spacer()
                Button { model.webView.goForward() } label: { Image(systemName: "chevron.forward") }
                    .disabled(!model.canGoForward)
                Spacer()
                Button {
                    model.isLoading ? model.webView.stopLoading() : model.webView.reload()
                } label: {
                    Image(systemName: model.isLoading ? "xmark" : "arrow.clockwise")
                }
                Spacer()
                if let url = URL(string: model.address), !model.address.isEmpty {
                    ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                } else {
                    Image(systemName: "square.and.arrow.up").foregroundStyle(.tertiary)
                }
                Spacer()
                Button { model.load(BrowserModel.home) } label: { Image(systemName: "house") }
            }
            .font(.title3)
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .onChange(of: model.address) { newValue in
            if !focused { text = newValue }
        }
    }
}

import SwiftUI
import SafariServices

// MARK: - SafariView
// UIViewControllerRepresentable que envuelve SFSafariViewController.
// Uso: .sheet(isPresented: $mostrandoPrivacidad) { SafariView(url: urlPrivacidad) }

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredBarTintColor    = UIColor(Color.Medical.background)
        safari.preferredControlTintColor = UIColor(Color.Medical.accent)
        safari.dismissButtonStyle = .close
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - LegalURLs
// Carga URLs desde Secrets.plist para no codificarlas en el binario.

struct LegalURLs {
    static let shared = LegalURLs()

    let privacidad: URL
    let terminos: URL
    let relevo: URL

    private init() {
        func loadURL(_ key: String, fallback: String) -> URL {
            guard
                let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
                let dict = NSDictionary(contentsOfFile: path) as? [String: String],
                let string = dict[key],
                let url = URL(string: string)
            else {
                return URL(string: fallback)!
            }
            return url
        }

        privacidad = loadURL("LEGAL_URL_PRIVACIDAD",
                             fallback: "https://tudominio.com/privacidad")
        terminos   = loadURL("LEGAL_URL_TERMINOS",
                             fallback: "https://tudominio.com/terminos")
        relevo     = loadURL("LEGAL_URL_RELEVO",
                             fallback: "https://tudominio.com/relevo-medico")
    }
}

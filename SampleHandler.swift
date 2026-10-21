// Extensión de transmisión: lee la pantalla de Didi y avisa con el semáforo.
import ReplayKit
import Vision
import UserNotifications

// ===== TUS LÍMITES (cámbialos aquí) =====
let minPorKm: Double = 3000
let minPorHora: Double = 30000
// ========================================

class SampleHandler: RPBroadcastSampleHandler {
    private var ultimaLectura = Date.distantPast
    private var ultimaOferta = ""

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {}

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with type: RPSampleBufferType) {
        guard type == .video,
              Date().timeIntervalSince(ultimaLectura) > 0.7,
              let pixeles = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        ultimaLectura = Date()

        let pedido = VNRecognizeTextRequest()
        pedido.recognitionLevel = .fast
        pedido.usesLanguageCorrection = false
        try? VNImageRequestHandler(cvPixelBuffer: pixeles, options: [:]).perform([pedido])
        let texto = (pedido.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
        analizar(texto)
    }

    private func numeros(_ patron: String, en texto: String) -> [Double] {
        guard let re = try? NSRegularExpression(pattern: patron) else { return [] }
        let rango = NSRange(texto.startIndex..., in: texto)
        return re.matches(in: texto, range: rango).compactMap { m in
            guard let r = Range(m.range(at: 1), in: texto) else { return nil }
            return Double(texto[r].replacingOccurrences(of: ",", with: "."))
        }
    }

    private func analizar(_ texto: String) {
        // Valor: $12.700 (el punto es separador de miles)
        guard let re = try? NSRegularExpression(pattern: "\\$\\s?(\\d{1,3}(?:\\.\\d{3})+)"),
              let m = re.firstMatch(in: texto, range: NSRange(texto.startIndex..., in: texto)),
              let r = Range(m.range(at: 1), in: texto),
              let valor = Double(texto[r].replacingOccurrences(of: ".", with: "")) else { return }

        // Suma recogida + viaje (hasta 2 de cada uno)
        let km = numeros("(\\d+(?:[.,]\\d+)?)\\s?km", en: texto).prefix(2).reduce(0, +)
        let min = numeros("(\\d+)\\s?min", en: texto).prefix(2).reduce(0, +)
        guard km > 0, min > 0 else { return }

        let clave = "\(valor)-\(km)-\(min)"
        guard clave != ultimaOferta else { return }
        ultimaOferta = clave

        let porKm = valor / km
        let porHora = valor * 60 / min
        let bueno = porKm >= minPorKm && porHora >= minPorHora
        let regular = porKm >= minPorKm * 0.8 && porHora >= minPorHora * 0.8
        let titulo = bueno ? "🟢 ¡Acéptalo!" : (regular ? "🟡 Tú decides" : "🔴 Rechaza")

        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "es_CO")
        f.maximumFractionDigits = 0
        let cuerpo = "$\(f.string(from: NSNumber(value: porKm)) ?? "")/km · $\(f.string(from: NSNumber(value: porHora)) ?? "")/h"

        let c = UNMutableNotificationContent()
        c.title = titulo
        c.body = cuerpo
        c.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
    }
}

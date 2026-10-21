import SwiftUI
import ReplayKit
import UserNotifications

struct BotonTransmision: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let v = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
        // Cambia por el identificador de tu extensión (ver LEEME)
        v.preferredExtension = "com.tunombre.DidiSemaforo.Transmision"
        v.showsMicrophoneButton = false
        return v
    }
    func updateUIView(_ v: RPSystemBroadcastPickerView, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Semáforo Didi").font(.largeTitle).bold()
            Text("1. Toca el botón de abajo y elige «Iniciar transmisión».\n2. Abre Didi. Cuando llegue una oferta, te avisa arriba.")
                .multilineTextAlignment(.center)
            BotonTransmision().frame(width: 90, height: 90)
        }
        .padding()
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
}

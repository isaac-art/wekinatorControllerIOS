import SwiftUI

@main
struct WekioscApp: App {
    @StateObject private var controller = WekController()

    var body: some Scene {
        WindowGroup {
            ContentView(controller: controller)
        }
    }
}

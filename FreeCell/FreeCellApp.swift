import SwiftUI

@main
struct FreeCellApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        // One game in one window. Closing the window quits the app.
        Window("FreeCell", id: "game") {
            GameView()
                .frame(minWidth: 640, minHeight: 480)
        }
        .defaultSize(width: 1200, height: 900)
        .commands { GameCommands() }
        #else
        WindowGroup {
            GameView()
        }
        .commands { GameCommands() }
        #endif
    }
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
#endif

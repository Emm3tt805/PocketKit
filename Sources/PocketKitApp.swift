import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.requestPermission()
        return true
    }

    // Show notifications as banners even while the app is open
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}

@main
struct PocketKitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timers = TimerStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timers)
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TimersView()
                .tabItem { Label("Timers", systemImage: "timer") }
            RemindersView()
                .tabItem { Label("Notify", systemImage: "bell.badge") }
            BrowserView()
                .tabItem { Label("Browser", systemImage: "globe") }
        }
    }
}

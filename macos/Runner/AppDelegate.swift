import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
   if #available(iOS 10.0, *) {
       // For iOS 10 display notification (sent via APNS)
       UNUserNotificationCenter.current().delegate = self
       let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
       UNUserNotificationCenter.current().requestAuthorization(
         options: authOptions,
         completionHandler: { _, _ in }
       )
     } else {
       let settings: UIUserNotificationSettings =
         UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
       application.registerUserNotificationSettings(settings)
     }
     application.registerForRemoteNotifications()
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}

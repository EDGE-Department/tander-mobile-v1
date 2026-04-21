import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Controls whether the app is locked to portrait orientation.
  /// When true, only portrait orientations are allowed (for liveness/ID verification screens).
  static var isPortraitLocked: Bool = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Required for flutter_local_notifications and firebase_messaging
    // to show notifications while app is in foreground.
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Called by iOS to determine which orientations are supported.
  /// This is the key method that enforces portrait lock on iPhones and iPads.
  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    if AppDelegate.isPortraitLocked {
      // Lock to portrait only (works on both iPhone and iPad)
      return .portrait
    }
    // Default: allow all orientations
    return .all
  }

  @available(iOS 16.0, *)
  private func setNeedsUpdateOfSupportedInterfaceOrientations() {
    window?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
  }
}

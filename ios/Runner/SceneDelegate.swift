import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  private var orientationChannel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let windowScene = scene as? UIWindowScene,
          let window = windowScene.windows.first,
          let controller = window.rootViewController as? FlutterViewController else {
      return
    }

    orientationChannel = FlutterMethodChannel(
      name: "com.tander.app/orientation",
      binaryMessenger: controller.binaryMessenger
    )

    orientationChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "lockPortrait":
        self?.setOrientationLock(true, windowScene: windowScene, window: window)
        result(nil)

      case "unlockOrientation":
        self?.setOrientationLock(false, windowScene: windowScene, window: window)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setOrientationLock(_ locked: Bool, windowScene: UIWindowScene, window: UIWindow) {
    AppDelegate.isPortraitLocked = locked
    let orientations: UIInterfaceOrientationMask = locked ? .portrait : .all

    if #available(iOS 16.0, *) {
      windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientations)) { error in
        // Geometry update completed (or failed) — refresh the view hierarchy
        DispatchQueue.main.async {
          window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
          // For iPad: also ask all presented view controllers to update
          var vc = window.rootViewController
          while let presented = vc?.presentedViewController {
            presented.setNeedsUpdateOfSupportedInterfaceOrientations()
            vc = presented
          }
        }
      }
    } else {
      // iOS 15 and earlier
      if locked {
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
      }
      UINavigationController.attemptRotationToDeviceOrientation()
    }
  }
}

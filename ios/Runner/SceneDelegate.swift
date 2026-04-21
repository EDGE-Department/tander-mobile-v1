import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

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

    let orientationChannel = FlutterMethodChannel(
      name: "com.tander.app/orientation",
      binaryMessenger: controller.binaryMessenger
    )

    orientationChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "lockPortrait":
        AppDelegate.isPortraitLocked = true
        if #available(iOS 16.0, *) {
          windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { _ in }
          window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
          UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
          UINavigationController.attemptRotationToDeviceOrientation()
        }
        result(nil)

      case "unlockOrientation":
        AppDelegate.isPortraitLocked = false
        if #available(iOS 16.0, *) {
          windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all)) { _ in }
          window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
          UINavigationController.attemptRotationToDeviceOrientation()
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

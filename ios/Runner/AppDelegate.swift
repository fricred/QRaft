import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var initialLink: String?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel for deeplinks
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }
    
    methodChannel = FlutterMethodChannel(name: "qraft/deeplink", binaryMessenger: controller.binaryMessenger)
    methodChannel?.setMethodCallHandler(handleMethodCall)
    
    // Check if app was opened from a URL
    if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
      initialLink = url.absoluteString
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle method calls from Flutter
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getInitialLink":
      result(initialLink)
      initialLink = nil // Clear after first call
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // Handle deep links when app is already running
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    methodChannel?.invokeMethod("routeUpdated", arguments: url.absoluteString)
    return true
  }
  
  // Handle universal links
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      methodChannel?.invokeMethod("routeUpdated", arguments: url.absoluteString)
      return true
    }
    return false
  }
}

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register audio recorder plugin
    let controller = window?.rootViewController as! FlutterViewController
    AudioRecorderPlugin.register(with: registrar(forPlugin: "AudioRecorderPlugin")!)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}


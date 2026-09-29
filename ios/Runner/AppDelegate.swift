import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Playback category keeps the stream running after the app leaves the
    // foreground, and remote commands surface play/pause in Control Center
    // and on the Lock Screen.
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    } catch {
      NSLog("Failed to set audio session category: \(error)")
    }
    application.beginReceivingRemoteControlEvents()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

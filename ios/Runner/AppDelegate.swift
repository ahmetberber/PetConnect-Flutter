import Flutter
import UIKit
import GoogleMaps
import GooglePlaces

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyCaCnDZHu-PCM2_UP0J4jodoocMf5mQwoc")
    GMSPlacesClient.provideAPIKey("AIzaSyCaCnDZHu-PCM2_UP0J4jodoocMf5mQwoc")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

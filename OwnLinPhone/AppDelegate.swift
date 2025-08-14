//
//  AppDelegate.swift
//  OwnLinPhone
//
//  Created by Haidarov N on 8/12/25.
//

import UIKit
import PushKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    var voipRegistry: PKPushRegistry!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        voipRegistry = PKPushRegistry(queue: .main)
            voipRegistry.desiredPushTypes = [.voIP]
            voipRegistry.delegate = self
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didUpdate pushCredentials: PKPushCredentials,
                      for type: PKPushType) {
        let tokenString = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        print("VoIP Token: \(tokenString)")
        // Send token to your SIP server push gateway
    }

    // Incoming VoIP push
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        // Parse SIP info from payload
        let handle = payload.dictionaryPayload["caller"] as? String ?? "Unknown"

        // Show native call UI
        DispatchQueue.main.async {
            guard CallManager.shared.currentCallUUID == nil else {
                print("📞 Call already exists")
                completion()
                return
            }
            let uuid = UUID()
//            CallManager.shared.reportIncomingCall(handle: handle) {
//                completion()
//            }
        }

    }

}


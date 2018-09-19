//
//  AppDelegate.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/27/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import AWSCore
import Firebase
import FacebookCore
import GoogleSignIn
import UserNotifications
import FirebaseInstanceID
import FirebaseMessaging
import JWTDecode

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    var tokenExpirationTime : Date?
    weak var timer: Timer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        return true
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let facebookDidHandle = SDKApplicationDelegate.shared.application(app, open: url, options: options)
        let googleDidHandle = GIDSignIn.sharedInstance().handle(url as URL?, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        return facebookDidHandle || googleDidHandle
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    // The callback to handle data message received via FCM for devices running iOS 10 or above.
    func applicationReceivedRemoteMessage(_ remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        timer?.invalidate()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        if let user = Auth.auth().currentUser {
            user.getIDTokenForcingRefresh(false){ (idToken, error) in
                do {
                    let jwt = try decode(jwt: idToken!)
                    self.tokenExpirationTime = jwt.expiresAt
                }
                catch {
                    self.tokenExpirationTime = nil
                }
            }
        }
        
        if let username = UserDefaults.standard.string(forKey: "KEY_USERNAME") {
            Database.database().reference().child(getUsernameHash(username: username) + "/\(username)/push/n").removeValue()
        }
        
        timer?.invalidate()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        //if token has already expired or is 15 minutes from expiration
        if tokenExpirationTime == nil  || tokenExpirationTime!.timeIntervalSinceNow.isLess(than: 900) {
            //force a relaunch from initial VC, which will refresh the token before presenting MainVC if user is currently logged in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            self.window?.rootViewController = storyboard.instantiateInitialViewController()
            
            self.setTokenAutoRefresh(period: 3480) //set token to refresh in 58 minutes, so 2 minutes before new token expiration
        }
        else {
            self.setTokenAutoRefresh(period: tokenExpirationTime!.timeIntervalSinceNow - 60) //set token to refresh 60 seconds before expiration
        }
        
        
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if let username = UserDefaults.standard.string(forKey: "KEY_USERNAME") {
            Database.database().reference().child(getUsernameHash(username: username) + "/\(username)/push/n").removeValue()
        }
        
        //clear any push notification displayed on the phone
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
    }
    
    func setTokenAutoRefresh(period : TimeInterval) {
        timer?.invalidate()   // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
        timer = Timer.scheduledTimer(withTimeInterval: period, repeats: false) { [weak self] _ in
            Auth.auth().currentUser!.getIDTokenForcingRefresh(true){ (idToken, error) in
                let oidcProvider = OIDCProvider(input: idToken! as NSString)
                let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1, identityPoolId:"us-east-1:88614505-c8df-4dce-abd8-79a0543852ff", identityProviderManager: oidcProvider)
                credentialsProvider.clearCredentials()
                let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
                //login session configuration is stored in the default
                AWSServiceManager.default().defaultServiceConfiguration = configuration
                
                //set timer task to refresh token in 58 minutes = 3480 seconds.
                self!.setTokenAutoRefresh(period: 3480)
            }
        }
    }
    
    

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        timer?.invalidate()
    }

    func getUsernameHash(username : String) -> String {
        var usernameHash : Int32
        if(username.count < 5){
            usernameHash = username.hashCode()
        }
        else{
            var hashIn = ""
            
            hashIn.append(username[0])
            hashIn.append(username[username.count-2])
            hashIn.append(username[1])
            hashIn.append(username[username.count-1])
            
            usernameHash = hashIn.hashCode()
        }
        
        return "\(usernameHash)"
    }

}


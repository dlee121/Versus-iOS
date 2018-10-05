//
//  AppDelegate.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/27/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import AWSCore
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase

import FacebookCore
import GoogleSignIn
import UserNotifications
import FirebaseInstanceID
import FirebaseMessaging
import JWTDecode
import Appodeal

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
        
        //if not in EU, go ahead and initialize Appodeal here with hasConsent = true
        if !isInEU() {
            Appodeal.initialize(withApiKey: "819054921bcb6cc21aa0e7a19f852d182975592b907d0ad3", types: .nativeAd, hasConsent: true)
        }
        
        return true
    }
    
    func isInEU() -> Bool {
        if let regionCode = Locale.current.regionCode {
            switch regionCode {
            case "AT":
                return true
            case "BE":
                return true
            case "BG":
                return true
            case "HR":
                return true
            case "CY":
                return true
            case "CZ":
                return true
            case "DK":
                return true
            case "EE":
                return true
            case "FI":
                return true
            case "FR":
                return true
            case "DE":
                return true
            case "GR":
                return true
            case "HU":
                return true
            case "IE":
                return true
            case "IT":
                return true
            case "LV":
                return true
            case "LT":
                return true
            case "LU":
                return true
            case "MT":
                return true
            case "NL":
                return true
            case "PL":
                return true
            case "PT":
                return true
            case "RO":
                return true
            case "SK":
                return true
            case "SI":
                return true
            case "ES":
                return true
            case "SE":
                return true
            case "GB":
                return true
            default:
                return false
            }
        }
        else {
            return false
        }
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
        
        if let token = UserDefaults.standard.object(forKey: "KEY_TOKEN") as? String {
            do {
                let jwt = try decode(jwt: token)
                self.tokenExpirationTime = jwt.expiresAt
            }
            catch {
                self.tokenExpirationTime = nil
            }
            
            if let username = UserDefaults.standard.string(forKey: "KEY_USERNAME") {
                Database.database().reference().child(getUsernameHash(username: username) + "/\(username)/push/n").removeValue()
            }
        }
        
        timer?.invalidate()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        //tokenExpirationTime = nil
        
        if Auth.auth().currentUser != nil {
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
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            } else {
                // Fallback on earlier versions
                application.applicationIconBadgeNumber = 0
                application.cancelAllLocalNotifications()
            }
        }
        
    }
    
    
    func setTokenAutoRefresh(period : TimeInterval) {
        timer?.invalidate()   // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: period, repeats: false) { [weak self] _ in
                Auth.auth().currentUser!.getIDTokenForcingRefresh(true){ (idToken, error) in
                    //store the fresh token in UserDefaults
                    UserDefaults.standard.set(idToken, forKey: "KEY_TOKEN")
                    
                    let oidcProvider = OIDCProvider(input: idToken! as NSString)
                    let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1, identityPoolId:"us-east-1:88614505-c8df-4dce-abd8-79a0543852ff", identityProviderManager: oidcProvider)
                    credentialsProvider.clearCredentials()
                    let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
                    //login session configuration is stored in the default
                    AWSServiceManager.default().defaultServiceConfiguration = configuration
                    
                    AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider.invalidateCachedTemporaryCredentials()
                    AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider.credentials()
                }
            }
        } else {
            // Fallback on earlier versions
            timer = Timer.scheduledTimer(timeInterval: period,
                                 target: self,
                                 selector: #selector(self.iOS9Timer),
                                 userInfo: nil,
                                 repeats: false)
        }
    }
    
    @objc
    func iOS9Timer() {
        Auth.auth().currentUser!.getIDTokenForcingRefresh(true){ (idToken, error) in
            //store the fresh token in UserDefaults
            UserDefaults.standard.set(idToken, forKey: "KEY_TOKEN")
            
            let oidcProvider = OIDCProvider(input: idToken! as NSString)
            let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1, identityPoolId:"us-east-1:88614505-c8df-4dce-abd8-79a0543852ff", identityProviderManager: oidcProvider)
            credentialsProvider.clearCredentials()
            let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
            //login session configuration is stored in the default
            AWSServiceManager.default().defaultServiceConfiguration = configuration
            
            AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider.invalidateCachedTemporaryCredentials()
            AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider.credentials()
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


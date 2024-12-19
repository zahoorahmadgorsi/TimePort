//
//  AppDelegate.swift
//  GoogleMapDemo
//
//  Created by Zahoor Ahmad Gorsi on 24/08/24.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //PERSONAL ACCOUNT KEY
//        GMSServices.provideAPIKey("AIzaSyA7nkSBdVKOjDqRoPMzT0ADfD_T_nWED7Y")
//        GMSPlacesClient.provideAPIKey("AIzaSyA7nkSBdVKOjDqRoPMzT0ADfD_T_nWED7Y")
        
        //REMYNDR KEY
//        GMSServices.provideAPIKey("AIzaSyD9TV65Hg2rGXHnPaV1LHNE5TTmtqr9pKQ")
//        GMSPlacesClient.provideAPIKey("AIzaSyD9TV65Hg2rGXHnPaV1LHNE5TTmtqr9pKQ")
        
        //LOGIRIDE KEY
//        GMSServices.provideAPIKey("AIzaSyAJSMZX87mB0SSPiSuyZpBkL2AVq2UchJQ")
//        GMSPlacesClient.provideAPIKey("AIzaSyAJSMZX87mB0SSPiSuyZpBkL2AVq2UchJQ")
        
        //NEW CLIENT KEY
        GMSServices.provideAPIKey("AIzaSyDu__0AxD6-yUvUlT9ytQjyw0K4g5d8h70")
        GMSPlacesClient.provideAPIKey("AIzaSyDu__0AxD6-yUvUlT9ytQjyw0K4g5d8h70")
        // Override point for customization after application launch.
        return true
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
           // The container that holds the Core Data stack
           let container = NSPersistentContainer(name: "PhotosHistoryDB") // Replace "YourModelName" with the name of your .xcdatamodeld file
           container.loadPersistentStores(completionHandler: { (storeDescription, error) in
               if let error = error as NSError? {
                   // If there's an error, replace this with appropriate error handling
                   fatalError("Unresolved error \(error), \(error.userInfo)")
               }
           })
           return container
       }()

       // MARK: - Core Data Saving support

       func saveContext() {
           let context = persistentContainer.viewContext
           if context.hasChanges {
               do {
                   try context.save()
               } catch {
                   let nserror = error as NSError
                   fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
               }
           }
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

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let rootViewController = window?.rootViewController {
            if rootViewController is CapturePhotoVC {
                return .landscape // Restrict only this view controller to landscape
            }
        }
        return .allButUpsideDown // Default to all orientations elsewhere in the app
    }



}


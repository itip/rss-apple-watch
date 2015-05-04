//
//  AppDelegate.swift
//  RSSWatch
//
//  Created by Ian Tipton on 01/05/2015.
//  Copyright (c) 2015. All rights reserved.
//

import UIKit
import CoreData
import WatchKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let navigationController = self.window!.rootViewController as! UINavigationController
        let controller = navigationController.topViewController as! FeedListTableViewController
        controller.managedObjectContext = self.managedObjectContext
               
        
//        let d = "Fri, 01 May 2015 11:18 EDT"
//        if let date = self.dateFromRFC822String(d){
//            println("\(date)")
//        }
        
        /*
          Listen out for Core Data changes made on different threads.
          See http://www.objc.io/issue-2/common-background-practices.html
         */
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: nil, queue: nil) { (notification) -> Void in
            
            // Make sure we merge on the main thread
            dispatch_async(dispatch_get_main_queue(),{
                
                let context = notification.object as! NSManagedObjectContext
                
                // Make sure we're merging the same type of data (only an issue if you use other
                // frameworks which use Core Data, e.g. Google Maps
                if context.persistentStoreCoordinator != self.managedObjectContext?.persistentStoreCoordinator{
                    return;
                }
                
                // Merge the data in (double check that the context isn't merging itself).
                if context != self.managedObjectContext{
                    self.managedObjectContext?.mergeChangesFromContextDidSaveNotification(notification)
                }
            })
        }
        
        return true
    }

    // MARK: - WatchKit
    
    func application(application: UIApplication,
        handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?,
        reply: (([NSObject : AnyObject]!) -> Void)!) {
            
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
            
        if let userInfo = userInfo, request = userInfo["request"] as? String {
            if request == "feedList" {
                
                // See if data has ever been downloaded. A more sophisticated solution would be to download data now.
                if NSUserDefaults.standardUserDefaults().valueForKey("feed_last_updated") == nil{
                    reply(["error": "never_launched"])
                    return
                }
                
                // Read the most recent 10 items from the database
                let fetchRequest = NSFetchRequest()
                let entity = NSEntityDescription.entityForName("Item", inManagedObjectContext: self.managedObjectContext!)
                fetchRequest.entity = entity
                fetchRequest.fetchLimit = 10;
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                
                var error:NSError?
                var feedItems = self.managedObjectContext!.executeFetchRequest(fetchRequest, error: &error) as? [Item]
                if (feedItems == nil || error != nil){
                    // If no data or if an error exists, something went wrong with query
                    reply(["error": "data"])
                    return
                }
                
                // Put data into an array of dictionaries (more efficient that serialising Core Data objects)
                var data = [[String:String]]()
                for item in feedItems! {
                    data.append([
                        "title":item.title,
                        "date": dateFormatter.stringFromDate(item.date),
                        "description" : item.desc,
                        "image" : item.image
                        
                    ])
                }
                
                reply(["listData": NSKeyedArchiver.archivedDataWithRootObject(data)])
                return
            }
            
        }
  
        // If we've reached here then it means something went wrong (or app requested data which isn't available)
        reply(["error": true])
    }
    
    
    // MARK: - Lifecycle
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.bronzelabs.RSSWatch" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("RSSWatch", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("RSSWatch.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }

}


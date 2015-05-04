//
//  FeedDownloader.swift
//  RSSWatch
//
//  Created by Ian Tipton on 01/05/2015.
//  Copyright (c) 2015. All rights reserved.
//

//
// Download RSS items
//

import Foundation
import CoreData

struct GlobalConstants {
    static let feedUrl = "http://www.nasa.gov/rss/dyn/lg_image_of_the_day.rss"
}

class FeedDownloader {
    
    private var managedObjectContext: NSManagedObjectContext!
    
    init(managedObjectContext: NSManagedObjectContext){

        // Create a new managed object context (as we're working on a separate thread)
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        self.managedObjectContext.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator
    }
    
    func download(#callback: (success:Bool)->Void) {
        
        // Read existing items from database. We'll remove items from this list while iterating.
        // Anything left is old and can be deleted.
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Item", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        var error:NSError?
        var items = self.managedObjectContext.executeFetchRequest(fetchRequest, error: &error) as? [Item]
        if (items == nil || error != nil){
            // If no data or if an error exists, something went wrong with query
            callback(success: false);
            return
        }
        
        let url = NSURL(string: GlobalConstants.feedUrl)
        let downloadTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in

            if error != nil{
                dispatch_async(dispatch_get_main_queue(),{
                    callback(success: false);
                })
                return;
            }
        
            
            let xml = SWXMLHash.parse(data)
            
//            let num = xml["rss"]["channel"]["item"].all.count
            
            for elem in xml["rss"]["channel"]["item"] {
                
//                if let title = elem["title"].element?.text {
//                    println("Title: \(title)")
//                }
//                else {
//                    println("no title")
//                }
//                
//                if let link = elem["link"].element?.text {
//                    println("link: \(link)")
//                }
//                else {
//                    println("no link")
//                }
//                
//                if let description = elem["description"].element?.text {
//                    println("description: \(description)")
//                }
//                else {
//                    println("no description")
//                }
//                
//                if let enclosure = elem["enclosure"].element?.attributes["url"] {
//                    println("enclosure: \(enclosure)")
//                }
//                else {
//                    println("no enclosure")
//                }
//                
//                if let pubDateValue = elem["pubDate"].element?.text {
////                    println("pubDateValue: \(pubDateValue)")
//                }
//                else {
//                    println("no pubDateValue")
//                }
                
                
                if let title = elem["title"].element?.text,
                        link = elem["link"].element?.text,
                        description = elem["description"].element?.text,
                        image = elem["enclosure"].element?.attributes["url"],
                        pubDateValue = elem["pubDate"].element?.text,
                        pubDate = self.dateFromRFC822String(pubDateValue) {
                    
                            
                    // See if we already have an item with this link (which should be unique)
                    var x=0
                    var foundItem = false;
                    for ; x < items!.count; x++ {
                        if items![x].link == link{
                            foundItem = true
                            break
                        }
                    }
                            
                    // If the item doesn't exist in our database, insert. Otherwise,
                    let item:Item!
                    if !foundItem{
                        item = NSEntityDescription.insertNewObjectForEntityForName("Item", inManagedObjectContext: self.managedObjectContext) as! Item
                    }
                    else {
                        item = items![x];
                        items!.removeAtIndex(x)
                    }
                        
                    item.title = title
                    item.link = link
                    item.desc = description
                    item.date = pubDate
                    item.image = image
                }
                
            }
            
            // By this point, anything left in the items array is old and can be deleted
            for item in items! {
                self.managedObjectContext.deleteObject(item)
            }
            
            var error: NSError? = nil
            if !self.managedObjectContext.save(&error) {

                // Unable to save data
                dispatch_async(dispatch_get_main_queue(),{
                    callback(success: false);
                })
                
                println("Error \(error)")
                return;
            }
            
            // Success !!
            dispatch_async(dispatch_get_main_queue(),{
                callback(success: true);
            })
        })
        downloadTask.resume()
    }
    
    /*
      Based on https://github.com/mwaterfall/MWFeedParser/blob/master/Classes/NSDate%2BInternetDateTime.m
     */
    func dateFromRFC822String(value: String) -> NSDate? {
        
        let locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        
        let RFC822String = value.uppercaseString
        
        if RFC822String.rangeOfString(",") != nil {
            dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"
            if let date = dateFormatter.dateFromString(value){
                return date
            }
            
            dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm zzz"
            if let date = dateFormatter.dateFromString(value){
                return date
            }
            
            dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss"
            if let date = dateFormatter.dateFromString(value){
                return date
            }
            
            dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm"
            if let date = dateFormatter.dateFromString(value){
                return date
            }
        }
        else {
            dateFormatter.dateFormat = "d MMM yyyy HH:mm:ss zzz"
            if let date = dateFormatter.dateFromString(value){
                return date
            }
            
            dateFormatter.dateFormat = "d MMM yyyy HH:mm zzz"
            if let date = dateFormatter.dateFromString(value){
                return date
            }
            
            dateFormatter.dateFormat = "d MMM yyyy HH:mm:ss"
            if let date = dateFormatter.dateFromString(value){
                return date
            }
            
            dateFormatter.dateFormat = "d MMM yyyy HH:mm"
            if let date = dateFormatter.dateFromString(value){
                return date
            }
        }
        
        return nil
    }
}

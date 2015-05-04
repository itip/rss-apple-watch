//
//  FeedListTableViewController.swift
//  RSSWatch
//
//  Created by Ian Tipton on 01/05/2015.
//  Copyright (c). All rights reserved.
//

//
// Display a list of items
//

import UIKit
import CoreData

class FeedListTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var managedObjectContext: NSManagedObjectContext? = nil
    private var dateFormatter: NSDateFormatter!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.dateFormatter = NSDateFormatter();
        self.dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        self.dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        
        // Add pull to refresh
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: Selector("refreshFeed:"), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl!.backgroundColor = UIColor.purpleColor()
        self.refreshControl!.tintColor = UIColor.whiteColor()
        
        let actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: Selector("refreshAction:"))
        self.navigationItem.rightBarButtonItem = actionButton
    }

    override func viewDidAppear(animated: Bool) {
        // Download items if we've never done it
        if NSUserDefaults.standardUserDefaults().valueForKey("feed_last_updated") == nil{
            self.refreshAction(nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UI
    
    func refreshAction(sender: AnyObject?){
        self.refreshControl!.beginRefreshing()
        
//        if self.tableView.frame.origin.y == 0 {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.tableView.contentOffset = CGPointMake(0, -140)
            })
            self.refreshFeed(sender)
//        }

    }
    
    func refreshFeed(sender: AnyObject?){
        
        // Download data
        let download = FeedDownloader(managedObjectContext: self.managedObjectContext!)
        download.download { (success) -> Void in
            
            if NSThread.isMainThread(){
                println("Main")
            }
            else{
                println("Not")
            }
            
            if !success {
                let alertView = UIAlertView(title: "Error", message: "Unable to download feed. Make sure you have an Internet connection and try again", delegate: nil, cancelButtonTitle: "OK")
                alertView.show()
            }
            else {
                // Update last refresh date
                let now = NSDate()
                NSUserDefaults.standardUserDefaults().setValue(now, forKey: "feed_last_updated")
                
                // Hide refresh control
                self.refreshControl!.endRefreshing()
            }
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if "SelectItem" == segue.identifier {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                var detailViewController = segue.destinationViewController as! FeedItemViewController
                detailViewController.selectedItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Item
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
                
        let item = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Item
        
        var imageView = cell.viewWithTag(1) as! UIImageView
        var titleLabel = cell.viewWithTag(2) as! UILabel
        var dateLabel = cell.viewWithTag(3) as! UILabel
        
        titleLabel.text = item.title
        dateLabel.text = self.dateFormatter.stringFromDate(item.date)
        
        if let url = NSURL(string: item.image), placeholder = UIImage(named: "loading") {
            imageView.sd_setImageWithURL(url, placeholderImage: placeholder)
        }
    
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Item", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        var error: NSError? = nil
        if !_fetchedResultsController!.performFetch(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
                self.configureCell(cell, atIndexPath: indexPath!)
            }
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

}

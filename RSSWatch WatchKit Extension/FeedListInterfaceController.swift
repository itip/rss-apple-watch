//
//  InterfaceController.swift
//  RSSWatch WatchKit Extension
//
//  Created by Ian Tipton on 04/05/2015.
//  Copyright (c) 2015 Bronze Software Labs. All rights reserved.
//

import WatchKit
import Foundation


class FeedListInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var feedListTable: WKInterfaceTable!
    @IBOutlet weak var errorMessageLabel: WKInterfaceLabel!
    
    private var feedItems: [[String:String]]?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        
//        Example 1
//        self.feedListTable.setNumberOfRows(10, withRowType: "FeedItem")
//
//        for var x=0; x < 10; x++ {
//            if let tableRow = self.feedListTable.rowControllerAtIndex(x) as? FeedListTableRow{
//                tableRow.headlineLabel.setText("Headline \(x+1)")
//                tableRow.subheadLabel.setText("Subhead \(x+1)")
//            }
//        }
        
        // Example 2
        //        WKInterfaceController.openParentApplication(["request": "feedList"],
        //            reply: { (replyInfo, error) -> Void in
        //
        //                if let listData = replyInfo["listData"] as? NSData {
        //                    if let feedItems = NSKeyedUnarchiver.unarchiveObjectWithData(listData) as? [[String:String]] {
        //
        //                        self.feedListTable.setNumberOfRows(feedItems.count, withRowType: "FeedItem")
        //
        //                        for (index, element) in enumerate(feedItems) {
        //                            if let tableRow = self.feedListTable.rowControllerAtIndex(index) as? FeedListTableRow{
        //                                let title = element["title"]
        //                                let date = element["date"]
        //
        //                                tableRow.headlineLabel.setText(title)
        //                                tableRow.subheadLabel.setText(date)
        //                            }
        //                        }
        //                    }
        //                }
        //        })
      
        // Hide error message label by default.
        self.errorMessageLabel.setHidden(true)
            
        WKInterfaceController.openParentApplication(["request": "feedList"],
            reply: { (replyInfo, error) -> Void in
                
                // Error checking. In the case of "never_launched", a more sophisticated solution would be to
                // trigger a data download.
                if let error = replyInfo["error"] as? String {
                    self.errorMessageLabel.setHidden(false)
                    
                    if error == "never_launched" {
                        self.errorMessageLabel.setText("Welcome. Please open the app on your phone to initialise")
                    }
                    else if error == "data" {
                        self.errorMessageLabel.setText("An error occurred when reading RSS items. Please try again")
                    }
                    
                    return
                }
                
                if let listData = replyInfo["listData"] as? NSData {
                    if let items = NSKeyedUnarchiver.unarchiveObjectWithData(listData) as? [[String:String]] {
                        self.feedItems = items
                        self.refreshTable()
                    }
                }
        })
    }
    
    func refreshTable(){
        if let items = self.feedItems {
            self.feedListTable.setNumberOfRows(items.count, withRowType: "FeedItem")
            
            for (index, element) in enumerate(items) {
                if let tableRow = self.feedListTable.rowControllerAtIndex(index) as? FeedListTableRow{
                    let title = element["title"]
                    let date = element["date"]
                    
                    tableRow.headlineLabel.setText(title)
                    tableRow.subheadLabel.setText(date)
                }
            }
        }
        else {
            self.feedListTable.setNumberOfRows(0, withRowType: "FeedItem")
        }
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        if segueIdentifier == "Detail" && self.feedItems != nil {
            return self.feedItems![rowIndex]
        }
        return nil
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}

//
//  FeedItemViewController.swift
//  RSSWatch
//
//  Created by Ian Tipton on 03/05/2015.
//  Copyright (c). All rights reserved.
//

//
// Display the selected item
//

import UIKit

class FeedItemViewController: UIViewController, UIActionSheetDelegate {

    var selectedItem: Item?
    
    private var dateFormatter: NSDateFormatter!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.dateFormatter = NSDateFormatter();
        self.dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        self.dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        let actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("openAction:"))
        self.navigationItem.rightBarButtonItem = actionButton
    }
    
    override func viewWillAppear(animated: Bool) {
        self.displayFeedItem()
    }

    func displayFeedItem(){
        
        self.title = self.selectedItem?.title ?? ""
        self.headlineLabel.text = self.selectedItem?.title ?? ""
        self.descriptionLabel.text = self.selectedItem?.desc ?? ""
        
        if let imageUrl = self.selectedItem?.image, url = NSURL(string: imageUrl), placeholder = UIImage(named: "loading") {
            imageView.sd_setImageWithURL(url, placeholderImage: placeholder)
        }
        
        if let pubDate = self.selectedItem?.date {
            dateLabel.text = self.dateFormatter!.stringFromDate(pubDate);
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    func openAction(object: AnyObject){
        let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Open in Safari")
        actionSheet.showInView(self.view)
    }
    
    // MARK: - UIActionSheetDelegate
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        
        if (buttonIndex == 1){
            if let urlValue = self.selectedItem?.link, url = NSURL(string: urlValue){
                UIApplication.sharedApplication().openURL(url)
            }
        }
    }

}

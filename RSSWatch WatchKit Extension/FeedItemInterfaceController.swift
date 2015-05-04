//
//  FeedITemInterfaceViewControllerInterfaceController.swift
//  RSSWatch
//
//  Created by Ian Tipton on 04/05/2015.
//  Copyright (c) 2015 Bronze Software Labs. All rights reserved.
//

import WatchKit
import Foundation


class FeedItemInterfaceController: WKInterfaceController {

    @IBOutlet weak var imageView: WKInterfaceImage!
    @IBOutlet weak var headlineLabel: WKInterfaceLabel!
    @IBOutlet weak var subheadLabel: WKInterfaceLabel!
    @IBOutlet weak var descriptionLabel: WKInterfaceLabel!
    
    private var currentItem: [String: AnyObject]?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.currentItem = context as? [String: AnyObject]
        self.displayFeedItem()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        self.displayImage()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    // MARK: - UI
    
    func displayFeedItem() {
        
        if self.currentItem != nil {
            let title = self.currentItem?["title"] as? String ?? ""
            let date = self.currentItem?["date"] as? String ?? ""
            let description = self.currentItem?["description"] as? String ?? ""
            
            self.headlineLabel.setText(title)
            self.subheadLabel.setText(date);
            self.descriptionLabel.setText(description)
            
            
        }
    }
    
    /*
      Display the image. We'll attempt to read from the cache if possible
     */
    func displayImage(){
        
        // When storing images in the device cache, we'll use the URL of the image as the key
        if let imageKey = self.currentItem?["image"] as? String {
        
            // See if image has already been cached
            for (key, value) in WKInterfaceDevice.currentDevice().cachedImages {
                if let imageName = key as? NSString, imageSize = value as? NSNumber {
                    if imageKey == imageName {
                        self.imageView.setImageNamed(imageKey)
                        return
                    }
                }
            }
            
            // If we've reached this point then it means we don't have the image in our cache. Download, resize, and cache
            if let url = NSURL(string: imageKey){
                let request = NSURLRequest(URL: url)
                
                let task = NSURLSession.sharedSession().downloadTaskWithRequest(request, completionHandler: { (imageUrl, response, error) -> Void in
                    
                    if error != nil {
                        NSLog("Unable to load image %@", error)
                        return;
                    }
                    
                    // We've downloaded the image, resize to fit Watch screen and store incache
                    if let image = UIImage(contentsOfFile: imageUrl.path!) {
                        
                        // Calculate width/height ratio of current image and resize the new image accordingly
                        let ratio = (image.size.width / image.size.height);
                        let deviceBounds = WKInterfaceDevice.currentDevice().screenBounds
                        let newHeight = deviceBounds.height / ratio
                        
                        // http://stackoverflow.com/a/2658801/578821
                        let newSize = CGSizeMake(deviceBounds.width, newHeight)
                        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
                        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
                        let newImage = UIGraphicsGetImageFromCurrentImageContext()
                        let newImageData = UIImagePNGRepresentation(newImage)
                        UIGraphicsEndImageContext()
                       
                        // We have the resized image. Cache.
                        if WKInterfaceDevice.currentDevice().addCachedImageWithData(newImageData, name: imageKey){
                            self.imageView.setImageNamed(imageKey)
                        }
                        else {
                            // Image couldn't be cached. This might be because cache is full. Try clearing cache.
                            // Note: ideally you'd want to just remove the oldest items but there isn't an API
                            // available so you'd need to implement that yourself
                            WKInterfaceDevice.currentDevice().removeAllCachedImages()
                            
                            if WKInterfaceDevice.currentDevice().addCachedImageWithData(newImageData, name: imageKey){
                                self.imageView.setImageNamed(imageKey)
                            }
                        }
                    }
                })
                task.resume()
            }
            
        }
    
    }
}

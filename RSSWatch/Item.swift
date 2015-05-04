//
//  Item.swift
//  
//
//  Created by Ian Tipton on 01/05/2015.
//
//

import Foundation
import CoreData

class Item: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var link: String
    @NSManaged var desc: String
    @NSManaged var date: NSDate
    @NSManaged var image: String

}

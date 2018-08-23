//
//  Photo+Properties.swift
//  Virtual Tourist
//
//  Created by akhil mantha on 23/08/18.
//  Copyright © 2018 akhil mantha. All rights reserved.
//

import Foundation
import CoreData


extension Photo {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }
    
    @NSManaged public var image: NSData?
    @NSManaged public var title: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var pin: Pin?
    
}

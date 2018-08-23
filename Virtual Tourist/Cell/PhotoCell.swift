//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by akhil mantha on 23/08/18.
//  Copyright © 2018 akhil mantha. All rights reserved.
//

import Foundation

class PhotoCell: UICollectionViewCell {
    static let identifier = "PhotoCell"
    
    var  imageUrl: String = ""
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
}


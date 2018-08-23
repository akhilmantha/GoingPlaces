//
//  PhotosParser.swift
//  Virtual Tourist
//
//  Created by akhil mantha on 23/08/18.
//  Copyright © 2018 akhil mantha. All rights reserved.
//

import Foundation
struct PhotosParser: Codable {
    let photos: Photos
}

struct Photos: Codable {
    let pages: Int
    let photo: [PhotoParser]
}

struct PhotoParser: Codable {
    
    let url: String?
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case url = "url_n"
        case title
    }
}

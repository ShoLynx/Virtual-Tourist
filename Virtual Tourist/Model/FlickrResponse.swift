//
//  FlickrResponse.swift
//  Virtual Tourist
//
//  Created by Administrator on 2/18/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
import UIKit

struct FlickrResponse: Codable {
    let photos: Photos
    let stat: String?
}

struct Photos: Codable {
    let page: Int?
    let pages: Int?
    let perpage: Int?
    let total: String?
    let photo: [Photo]
}

struct Photo: Codable {
    let id: String?
    let server: String?
    let secret: String
    let farm: Int?
    let ispublic: Int?
    let url_n: String?
    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case owner
//        case secret
//        case server
//        case farm
//        case title
//        case ispublic
//        case isfriend
//        case isfamily
//        case urlN = "url_n"
//        case heightN = "height_n"
//        case widthN = "width_n"
//    }
}

struct PhotoPool {
    static var photo = [Photo]()
}

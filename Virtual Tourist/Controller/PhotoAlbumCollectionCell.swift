//
//  PhotoAlbumCollectionCell.swift
//  Virtual Tourist
//
//  Created by Administrator on 2/17/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
import UIKit

class PhotoAlbumCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var pinImage: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    func configure(with model: FlickrPhoto) {
        if model.imageData != nil {
            pinImage.image = UIImage(data: model.imageData!)
        } else {
            pinImage.image = UIImage(named: "imagePlaceholder")
        }
    }
    
    
}



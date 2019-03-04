//
//  PhotoAlbumController.swift
//  Virtual Tourist
//
//  Created by Administrator on 2/17/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PhotoAlbumController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var zoomedMap: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    
    var selectedPinCoordinates: CLLocationCoordinate2D?
    var imageData = PhotoPool.photo
    var images = [UIImage]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        noImagesLabel.isHidden = true
        newCollectionButton.isEnabled = false
        getImageFromURL()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setCollectionFormat()
        photoCollection!.reloadData()
        setPin(coordinates: selectedPinCoordinates!)
    }
    
    fileprivate func setCollectionFormat() {
        let space: CGFloat = 3.0
        let size = self.view.frame.size
        let dWidth = (size.width - (3 * space)) / 3.0
        let dHeight = (size.height - (3 * space)) / 4.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dWidth, height: dHeight)
    }
    
    fileprivate func getImageFromURL() {
        for photo in imageData {
            AppClient.downloadPhoto(url: URL(string: photo.url_n!)!, completionHandler: handlePhotoDownloadResponse(image:error:))
        }
    }
    
    func setPin(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        let latitudeMeters: CLLocationDistance = 100000
        let longitudeMeters: CLLocationDistance = 100000
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: latitudeMeters, longitudinalMeters: longitudeMeters)
        annotation.coordinate = coordinates
        zoomedMap.addAnnotation(annotation)
        zoomedMap.setRegion(region, animated: true)
    }
    
    func handlePhotoDownloadResponse(image: UIImage?, error: Error?) {
        if image != nil {
            images.append(image!)
            newCollectionButton.isEnabled = true
        } else {
            print(error!)
        }
    }
    
    func showErrorAlert(message: String) {
        let alertVC = UIAlertController(title: "Problem Getting Data", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }
    
    //This button resets the collection view to zero and gets more images
    @IBAction func newCollectionTapped(sender: UIButton) {
        images = []
        newCollectionButton.isEnabled = false
        photoCollection.reloadData()
        getImageFromURL()
    }
    
    //This provides an alert for users to confirm deleting a photo from the collection.  Add to didSelectItem at
    func deleteAlert() {
        
    }
    
    @IBAction func backToMap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}

extension PhotoAlbumController {
    //   Need function for counting the number of available images in a download
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageData.count
    }
    //    Need function that will fill the collection view with images
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionCell", for: indexPath) as! PhotoAlbumCollectionCell
        cell.activityIndicator.startAnimating()
        if images != [] {
            let image = images[(indexPath as NSIndexPath).row]
            cell.pinImage.image = image
            cell.activityIndicator.stopAnimating()
        } else {
            noImagesLabel.isHidden = false
            cell.activityIndicator.stopAnimating()
        }
        
        return cell
    }
    
//  this code is needed to remove a cell from the collection and flow the remaining cells to the empty cells
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        images.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
    }
}

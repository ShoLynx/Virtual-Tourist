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
import CoreData

class PhotoAlbumController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var zoomedMap: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    var pin: Pin!
    var selectedPinCoordinates: CLLocationCoordinate2D?
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<FlickrPhoto>!
    var imagePool = PhotoPool.photo
//    var images = [UIImage]()
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<FlickrPhoto> = FlickrPhoto.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "imageURL", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noImagesLabel.isHidden = true
        newCollectionButton.isEnabled = false

        setupFetchedResultsController()
        getImageURL()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCollectionFormat()
        photoCollection!.reloadData()
        
        setPin(coordinates: selectedPinCoordinates!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
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
    
    func getImageURL () {
        for photo in imagePool {
            let flickrPhoto = FlickrPhoto(context: dataController.viewContext)
            flickrPhoto.imageURL = photo.url_n
        }
    }
    
//    fileprivate func getImageFromURL() {
//        for flickrPhoto in fetchedResultsController.fetchedObjects ?? [] {
//            AppClient.downloadPhoto(url: URL(string: flickrPhoto.imageURL!)!, completionHandler: handlePhotoDownloadResponse(image:error:))
//        }
//    }
    
    func setPin(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        let latitudeMeters: CLLocationDistance = 100000
        let longitudeMeters: CLLocationDistance = 100000
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: latitudeMeters, longitudinalMeters: longitudeMeters)
        annotation.coordinate = coordinates
        zoomedMap.addAnnotation(annotation)
        zoomedMap.setRegion(region, animated: true)
    }
    
    func handlePhotoDataResponse (photos: [Photo]?, error: Error?) {
        if photos != nil {
            getImageURL()
        } else {
            print(error!)
        }
    }
    
    func handleURLResponse (flickrPhoto: [String]?, error: Error?) {
        if flickrPhoto != nil {
            for flickrPhoto in fetchedResultsController.fetchedObjects ?? [] {
                AppClient.downloadPhoto(url: URL(string: flickrPhoto.imageURL!)!, completionHandler: handlePhotoDownloadResponse(image:error:))
            }
        } else {
            print(error!)
        }
    }
    
    func handlePhotoDownloadResponse(image: UIImage?, error: Error?) {
        if image != nil {
            let flickrPhoto = FlickrPhoto(context: dataController.viewContext)
            flickrPhoto.imageData = image!.pngData()! as Data
            newCollectionButton.isEnabled = true
        } else {
            print(error!)
        }
    }
    
    @IBAction func newCollectionTapped(sender: UIButton) {
        let coordinateString = "&lat=\(selectedPinCoordinates!.latitude)&lon=\(selectedPinCoordinates!.longitude)"
        //empty PhotoPool.photo
        PhotoPool.photo = []
        //empty fetchedResultsController and clear the photoCollection
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FlickrPhoto")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try dataController.viewContext.execute(batchDeleteRequest)
            dataController.viewContext.reset()
            photoCollection.reloadData()
        } catch {
            fatalError("The delete process could not be completed. \(error.localizedDescription)")
        }
        //Run getPhotoData with completion handler handlePhotoDataResponse(Run downloadPhoto)
        AppClient.getPhotoData(coordinates: coordinateString, completion: handlePhotoDataResponse)
    }
    
//    func showErrorAlert(message: String) {
//        let alertVC = UIAlertController(title: "Problem Getting Data", message: message, preferredStyle: .alert)
//        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        show(alertVC, sender: nil)
//    }
    
    //This provides an alert for users to confirm deleting a photo from the collection.  Add to didSelectItem at
    func deleteAlert() {
        
    }
    
    @IBAction func backToMap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}

extension PhotoAlbumController: NSFetchedResultsControllerDelegate {
    //   Need function for counting the number of available images in a download
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    //    Need function that will fill the collection view with images
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionCell", for: indexPath) as! PhotoAlbumCollectionCell
        let cellImage = fetchedResultsController.object(at: indexPath)
        cell.pinImage.image = UIImage(data: cellImage.imageData!)
        
        return cell
    }
    
//  this code is needed to remove a cell from the collection and flow the remaining cells to the empty cells
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deleteItems(at: [indexPath])
    }

}

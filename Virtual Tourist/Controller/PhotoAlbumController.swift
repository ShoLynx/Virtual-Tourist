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

class PhotoAlbumController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var zoomedMap: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    var pin: Pin!
    var selectedPinCoordinates: CLLocationCoordinate2D?
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<FlickrPhoto>!
    var imagePool: [Photo] = []
    var photoArray: [FlickrPhoto] = []
    
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
        photoCollection.delegate = self
        photoCollection.dataSource = self
        setCollectionFormat()

        setupFetchedResultsController()
        AppClient.getPhotoData(coordinates: pin.coordinateString!, completion: handlePhotoDataResponse(photos:error:))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        setPin(coordinates: selectedPinCoordinates!)
        photoCollection.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        TLMapController().dataController = dataController
        
        //Empty the arrays
        PhotoPool.photo = []
        photoArray = []
        batchDeleteRequest()
        
//        pin = nil
//        TLMapController().selectedPin = nil
    }
    
    fileprivate func setCollectionFormat() {
        let space: CGFloat = 0.0
        let size = self.view.frame.size
        let dWidth = (size.width - (space)) / 2.0
        let dHeight = (size.height - (space)) / 5.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dWidth, height: dHeight)
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
    
    @IBAction func reloadCollectionView(_ sender: Any) {
        photoCollection.reloadData()
    }
    
    func getImageURL () {
        for photo in imagePool {
            let flickrPhoto = FlickrPhoto(context: dataController.viewContext)
            flickrPhoto.imageURL = photo.url_n
            photoArray.append(flickrPhoto)
        }
        
        DispatchQueue.main.async {
            try? self.dataController.viewContext.save()
            self.photoCollection.reloadData()
        }
    }
    
    func handlePhotoDataResponse (photos: [Photo]?, error: Error?) {
        if photos != nil {
            imagePool = photos!
            getImageURL()
            newCollectionButton.isEnabled = true
        } else {
            print(error!)
            noImagesLabel.isHidden = false
        }
    }
    
    fileprivate func batchDeleteRequest() {
        //empty fetchedResultsController and clear the photoCollection
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FlickrPhoto")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try dataController.viewContext.execute(batchDeleteRequest)
//            dataController.viewContext.reset()
            photoCollection.reloadData()
        } catch {
            fatalError("The delete process could not be completed. \(error.localizedDescription)")
        }
    }
    
    @IBAction func newCollectionTapped(_ sender: Any) {
        //disable NewCollectionButton
        self.newCollectionButton.isEnabled = false
        //empty PhotoPool.photo
        PhotoPool.photo = []
        photoArray = []
        batchDeleteRequest()
        setupFetchedResultsController()
        //Run getPhotoData with completion handler handlePhotoDataResponse(Run downloadPhoto)
        AppClient.getPhotoData(coordinates: pin.coordinateString!, completion: handlePhotoDataResponse)
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
    
    //   Need function for counting the number of available images in a download
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoArray.count
    }
    //    Need function that will fill the collection view with images
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionCell", for: indexPath) as! PhotoAlbumCollectionCell
        cell.pinImage.image = UIImage(named: "imagePlaceholder")
        let cellImage = photoArray[indexPath.row]
        let url = URL(string: cellImage.imageURL!)!
        DispatchQueue.main.async {
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.hidesWhenStopped = true
        }
        
        AppClient.downloadPhoto(url: url) { (data, error) in
            if error == nil {
                if let data = data {
                    DispatchQueue.main.async {
                        cellImage.imageData = data
                        try? self.dataController.viewContext.save()
                        cell.pinImage.image = UIImage(data: data)
                        cell.setNeedsLayout()
                        cell.activityIndicator.stopAnimating()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error!)
                }
            }
        }

        return cell
    }
    
//  this code is needed to remove a cell from the collection and flow the remaining cells to the empty cells
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Add code to remove related flickrPhoto from fetchedResultsController
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        for photo in photoArray {
            if photo.imageData == photoToDelete.imageData{
                dataController.viewContext.delete(photoToDelete)
                try? dataController.viewContext.save()
            }
        }
        collectionView.deleteItems(at: [indexPath])
        photoArray.remove(at: indexPath.row)
    }

}

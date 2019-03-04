//
//  AppClient.swift
//  Virtual Tourist
//
//  Created by Administrator on 2/17/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class AppClient {
    
    //MARK: APIs and contact URLs
    static var apiKey = "d26903be8565e2dde8b47edd610f600c"
    static var secret = "6d2d350b627a353e"
    
    //create endpoints
    enum Endpoints {
        static let flickrURL = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)"
        static let testURL =  "https://api.flickr.com/services/rest?nojsoncallback=1&format=json&per_page=30&page=1&api_key=e642c34c6ac8532ef77a7ec1c221babc"
        
        case getData(String)
        case test
        
        var stringValue: String {
            switch self {
                case .getData(let coordinates): return Endpoints.flickrURL + "&accuracy=11\(coordinates)&extras=url_n&per_page=30&format=json&nojsoncallback=1"
                case .test: return Endpoints.testURL + "&method=flickr.photos.search&safe_search=1&bbox=22.702575359394466,40.413855425758655,23.102575359394464,40.81385542575866&extras=url_n"
            }
        }
        
        var url: URL {
            return URL(string: self.stringValue)!
        }
    }
    
    
    //Global Functions
    
    class func getPhotoData(coordinates: String, completion: @escaping([Photo]?, Error?) -> Void) {
        let target = Endpoints.getData(coordinates).url
        let task = URLSession.shared.dataTask(with: target) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            do {
                let decoder = JSONDecoder()
//                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let responseObject = try decoder.decode(FlickrResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject.photos.photo, nil)
                    PhotoPool.photo = responseObject.photos.photo
                    print(String(data: data, encoding: .utf8)!)
                }
            } catch {
                do {
                    let decoder = JSONDecoder()
                    let errorResponse = try decoder.decode(EResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                        print(String(data: data, encoding: .utf8)!)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
    }
    
    class func downloadPhoto(url: URL, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            let downloadedImage = UIImage(data: data)
            completionHandler(downloadedImage, nil)
        })
        task.resume()
    }
    
}

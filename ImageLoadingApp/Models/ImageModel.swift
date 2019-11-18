//
//  ImageModel.swift
//  ImageLoadingApp
//
//  Created by Sergii Nesteruk on 10/10/19.
//  Copyright © 2019 NLab. All rights reserved.
//

import Foundation
import UIKit

struct ImageModel {
    let imageURL: URL
    let name: String
    
    init?(imageURLString: String, name: String) {
        guard let url = URL(string: imageURLString) else { return nil }
        self.imageURL = url
        self.name = name
    }
    
    static func loadData() -> [ImageModel] {
        var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
        var plistData: [String: String] = [:] //Our data
        let plistPath = Bundle.main.path(forResource: "ClassicPhotosDictionary", ofType: "plist")! //the path of the data
        let plistXML = FileManager.default.contents(atPath: plistPath)!
        do {//convert the data to a dictionary and handle errors.
            plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListFormat) as! [String: String]

        } catch {
            print("Error reading plist: \(error), format: \(propertyListFormat)")
        }
        
        var models = [ImageModel]()
        for (key, value) in plistData {
            if let model = ImageModel(imageURLString: value, name: key) {
                models.append(model)
            }
        }
        
        return models
    }
}

class ImageLoader: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    static let instance = ImageLoader()
    static let sessionID = "com.NLab.ImageLoadingApp.BackgroundSession"
    private let cache = Cache()
    private var backgroundSession: URLSession!
    private var completionsDictionary = [String: (UIImage?) -> Void]()
    
    private override init () {
        super.init()
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: ImageLoader.sessionID)
        backgroundConfiguration.isDiscretionary = false
        backgroundConfiguration.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: nil)
    }
    
    func check() {} // Currently is supposed for restarting from app relaunch in background
    
    func getImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        if let image = cache.getImageFromCache(image: url) {
            completion(image)
        } else {
            // Start download
            let task = backgroundSession.downloadTask(with: url)
            completionsDictionary[cache.imageFileName(url: url)] = completion
            task.resume()
        }
    }
    
    // MARK: - URLSessionDownloadDelegate methods
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let imageURL = downloadTask.response?.url else { return }
        cache.save(imageDataFileURL: location, forImageURL: imageURL)
        let completionKey = cache.imageFileName(url: imageURL)
        guard let imageData = try? Data(contentsOf: imageURL),
        let image = UIImage.init(data: imageData),
        let completion = completionsDictionary[completionKey]
        else { return }
        completionsDictionary.removeValue(forKey: completionKey)
        completion(image)
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let backgroundCompletionHandler =
                appDelegate.backgroundCompletionHandler else {
                    return
            }
            backgroundCompletionHandler()
        }
    }
    
    // MARK: - Cache
    class Cache {
        func getImageFromCache(image url: URL) -> UIImage? {
            guard let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            let imageURL = documentsPathURL.appendingPathComponent(imageFileName(url: url))
            guard let imageData = try? Data(contentsOf: imageURL) else { return nil }
            guard let image = UIImage.init(data: imageData) else { return nil }
            return image
        }
        
        func imageFileName(url: URL) -> String {
            let path = url.path.replacingOccurrences(of: "/", with: "_")
            return path
        }
        
        func save(image: UIImage, for url: URL) {
            guard let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let imageURL = documentsPathURL.appendingPathComponent(imageFileName(url: url))
            guard let data = image.pngData() else { return }
            _ = try? data.write(to: imageURL)
        }
        
        func save(imageDataFileURL fileURL: URL, forImageURL imageURL: URL) {
            guard let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let imageFileURL = documentsPathURL.appendingPathComponent(imageFileName(url: imageURL))
            _ = try? FileManager.default.moveItem(at: fileURL, to: imageFileURL)
        }
    }
}

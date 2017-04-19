//
//  UIImageView+Ext.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-18.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    
    func loadImageUsingCache(withUrlString urlString: String) {
        image = nil
        
        // check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            self.image = cachedImage
            return
        }
        
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }
            if let downloadedImage = UIImage(data: data!) {
                imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                
                DispatchQueue.main.async(execute: {
                    self.image = downloadedImage
                })
            }
        }).resume()
    }
}

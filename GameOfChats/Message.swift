//
//  Message.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-18.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    
    var id: String?
    var fromUid: String?
    var toUid: String?
    var text: String?
    var imageUrl: String?
    var timestamp: Double?
    var imageWidth: Float?
    var imageHeight: Float?
    var videoUrl: String?
    
    convenience init(dictionary: [String: Any]) {
        self.init()
        
        fromUid = dictionary["fromUid"] as? String
        toUid = dictionary["toUid"] as? String
        text = dictionary["text"] as? String
        imageUrl = dictionary["imageUrl"] as? String
        timestamp = dictionary["timestamp"] as? Double
        imageWidth = dictionary["imageWidth"] as? Float
        imageHeight = dictionary["imageHeight"] as? Float
        videoUrl = dictionary["videoUrl"] as? String
    }
    
    func chatPartnerId() -> String? {
        return fromUid == FIRAuth.auth()?.currentUser?.uid ? toUid : fromUid
    }
}

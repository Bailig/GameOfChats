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
    var timestamp: String?
    
    func chatPartnerId() -> String? {
        return fromUid == FIRAuth.auth()?.currentUser?.uid ? toUid : fromUid
    }
}

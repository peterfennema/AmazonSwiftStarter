//
//  UserData.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 08/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import Foundation

protocol UserData: class {
    
    var userId: String?  {get set}
    
    var name: String?  {get set}
    
    var imageData: Data? {get set}
    
}

extension UserData {
    
    func updateWithData(_ data: UserData) {
        
        // We can only set a new userId, not overwrite an existing userId 
        if self.userId == nil && data.userId != nil {
            self.userId = data.userId
        } 
        
        if self.name != data.name {
            self.name = data.name
        }
        if needsUpdate(self.imageData, withImageData: data.imageData) {
            self.imageData = data.imageData
        }
    }
    
    
    fileprivate func needsUpdate(_ imageData1: Data?, withImageData imageData2: Data?) -> Bool {
        if (imageData1 == nil && imageData2 == nil) {
            return false
        }
        if let imageData1 = imageData1, let imageData2 = imageData2 {
            if imageData1 == imageData2 {
                return false
            }
        }
        return true
    }
    
}

class UserDataValue: UserData {
    
    var userId: String?
    
    var name: String?
    
    var imageData: Data? 
    
}

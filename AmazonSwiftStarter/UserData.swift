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
    
    var imageData: NSData? {get set}
    
}

extension UserData {
    
    func updateWithData(data: UserData) {
        
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
    
    
    private func needsUpdate(imageData1: NSData?, withImageData imageData2: NSData?) -> Bool {
        if (imageData1 == nil && imageData2 == nil) {
            return false
        }
        if let imageData1 = imageData1, imageData2 = imageData2 {
            if imageData1.isEqualToData(imageData2) {
                return false
            }
        }
        return true
    }
    
}

class UserDataValue: UserData {
    
    var userId: String?
    
    var name: String?
    
    var imageData: NSData? 
    
}
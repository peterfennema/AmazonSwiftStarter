//
//  AMZUser.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 08/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import Foundation
import AWSDynamoDB

class AMZUser: AWSDynamoDBObjectModel ,AWSDynamoDBModeling, UserData {
    
    var userId: String?
    
    var name: String?
    
    // This attribute is not stored in dynamoDB, see ignoreAttributes(). We will store the image in S3.
    var imageData: NSData?
    
    var dum = "@"

    convenience init(userId: String) {
        self.init()
        self.userId = userId
    }
    
    static func dynamoDBTableName() -> String! {
        return "AmazonSwiftStarterUsers"
    }
    
    static func hashKeyAttribute() -> String! {
        return "userId"
    }
    
    static func ignoreAttributes() -> [AnyObject]! {
        return ["imageData"]
    }

}
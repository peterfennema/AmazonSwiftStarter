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
    
    // I discovered that when you try to save an item to DynamoDB with only a primary key and without any other attribute the item is not saved.
    // I think this is a bug. As an ugly workaround I have added this property :(
    // Might be related to this bug report on the aws-sdk-net: https://github.com/aws/aws-sdk-net/issues/106
    var dum = "@"

    convenience init(userId: String) {
        self.init()
        self.userId = userId
    }

    static func dynamoDBTableName() -> String! {
        return AMZConstants.DYNAMODB_USERS_TABLE
    }
    
    // This is the primary key that you configured while setting up the DynamoDB service.
    static func hashKeyAttribute() -> String! {
        return "userId"
    }
    
    // not stored in dynamoDB
    static func ignoreAttributes() -> [AnyObject]! {
        return ["imageData"]
    }

}
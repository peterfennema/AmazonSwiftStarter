//
//  AMZRemoteServiceWithTestTools.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 24/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import Foundation
@testable import AmazonSwiftStarter

class AMZRemoteServiceWithTestTools: AMZRemoteService, RemoteServiceWithTestTools {
    
    private static var sharedInstance: AMZRemoteServiceWithTestTools?
    
    static func defaultService() -> RemoteServiceWithTestTools {
        if sharedInstance == nil {
            sharedInstance = AMZRemoteServiceWithTestTools()
            sharedInstance!.configure()
        }
        return sharedInstance!
    }
    
    func removeCurrentUser() {
        identityProvider?.clearKeychain()
        persistentUserId = nil
        currentUser = nil
    }
    
}

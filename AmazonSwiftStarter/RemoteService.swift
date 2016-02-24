//
//  RemoteService.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 09/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import Foundation

typealias UserDataResultBlock = (userData: UserData?, error: NSError?) -> Void
typealias ErrorResultBlock = (error: NSError?) -> Void

protocol RemoteService {
    
    var currentUser: UserData? {get}
    
    func createCurrentUser(userData: UserData? , completion: ErrorResultBlock)
    
    func updateCurrentUser(userData: UserData, completion: ErrorResultBlock)
    
    func fetchCurrentUser(completion: UserDataResultBlock )
    
}




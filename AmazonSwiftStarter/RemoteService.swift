//
//  RemoteService.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 09/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import Foundation

typealias UserDataResultBlock = (_ userData: UserData?, _ error: NSError?) -> Void
typealias ErrorResultBlock = (_ error: NSError?) -> Void

protocol RemoteService {
    
    var hasCurrentUserIdentity: Bool {get}
    
    var currentUser: UserData? {get}
    
    func createCurrentUser(_ userData: UserData? , completion: @escaping ErrorResultBlock)
    
    func updateCurrentUser(_ userData: UserData, completion: @escaping ErrorResultBlock)
    
    func fetchCurrentUser(_ completion: @escaping UserDataResultBlock )
    
}




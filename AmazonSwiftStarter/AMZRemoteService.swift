//
//  AMZRemoteService.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 16/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import Foundation

class AMZRemoteService {
    
    var currentUser: UserData?

    fileprivate static var sharedInstance: AMZRemoteService?
    
    fileprivate init() {}
    
    static func defaultService() -> RemoteService {
        if sharedInstance == nil {
            sharedInstance = AMZRemoteService()
        }
        return sharedInstance!
    }
    
    fileprivate func randomWait() {
        let randomWaitingTime = arc4random_uniform(2 * 1000000)
        usleep(randomWaitingTime)
    }
    
}

extension AMZRemoteService: RemoteService {
    
    
    func createCurrentUser(_ userData: UserData? , completion: @escaping ErrorResultBlock) {
        assert(currentUser == nil, "currentUser should not exist when createCurrentUser(..) is called")
        assert(userData == nil || userData!.userId == nil, "You can not create a user with a given userId. UserIds are assigned automatically")
        OperationQueue().addOperation {
            // simulate a network call delay
            self.randomWait()
            let newUserData = UserDataValue()
            if let userData = userData {
                newUserData.updateWithData(userData)
            }
            newUserData.userId = UUID().uuidString
            self.currentUser = newUserData
            completion(nil)
        }
    }
    
    func updateCurrentUser(_ userData: UserData, completion: @escaping ErrorResultBlock) {
        assert(currentUser != nil, "currentUser should already exist when updateCurrentUser(..) is called")
        assert(userData.userId == nil || userData.userId == currentUser!.userId, "Updating current user with a different userId is not allowed")
        OperationQueue().addOperation {
            // simulate a network call delay
            self.randomWait()
            self.currentUser!.updateWithData(userData)
            completion(nil)
        }
    }
    
    func fetchCurrentUser(_ completion: @escaping UserDataResultBlock ) {
        OperationQueue().addOperation {
            // simulate a network call delay
            self.randomWait()
            // simulate the fetched result by returning the currentUser
            completion(self.currentUser, nil)
        }
    }
    
    
}

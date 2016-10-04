//
//  AMZRemoteService.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 16/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import Foundation
import AWSCore
import AWSDynamoDB
import AWSS3

class AMZRemoteService {
    
    // MARK: - RemoteService Properties
    
    var hasCurrentUserIdentity: Bool {
        return persistentUserId != nil
    }

    var currentUser: UserData?
    
    // MARK: - Properties

    var persistentUserId: String? {
        set {
            UserDefaults.standard.setValue(newValue, forKey: "userId")
            UserDefaults.standard.synchronize()
        }
        get {
            return UserDefaults.standard.string(forKey: "userId")
        }
    }
    
    fileprivate (set) var identityProvider: AWSCognitoCredentialsProvider?
    
    fileprivate var deviceDirectoryForUploads: URL?
    
    fileprivate var deviceDirectoryForDownloads: URL?
    
    fileprivate static var sharedInstance: AMZRemoteService?
    
    
    // MARK: - Functions
    
    static func defaultService() -> RemoteService {
        if sharedInstance == nil {
            sharedInstance = AMZRemoteService()
            sharedInstance!.configure()
        }
        return sharedInstance!
    }
    
    func configure() {
        identityProvider = AWSCognitoCredentialsProvider(
            regionType: AMZConstants.COGNITO_REGIONTYPE,
            identityPoolId: AMZConstants.COGNITO_IDENTITY_POOL_ID)
        
        let configuration = AWSServiceConfiguration(
            region: AMZConstants.DEFAULT_SERVICE_REGION,
            credentialsProvider: identityProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // The api I am using for uploading to and downloading from S3 (AWSS3TransferManager)can not deal with NSData directly, but uses files.
        // I need to create tmp directories for these files.
        deviceDirectoryForUploads = createLocalTmpDirectory("upload")
        deviceDirectoryForDownloads = createLocalTmpDirectory("download")
    }

    fileprivate func createLocalTmpDirectory(_ directoryName: String) -> URL? {
        do {
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(directoryName)
            try
                FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil)
            return url
        } catch let error as NSError {
            print("Creating \(directoryName) directory failed. Error: \(error)")
            return nil
        }
    }
    
    // This is where the saving to S3 (image) and DynamoDB (data) is done.
    func saveAMZUser(_ user: AMZUser, completion: @escaping ErrorResultBlock)  {
        precondition(user.userId != nil, "You should provide a user object with a userId when saving a user")
        
        let mapper = AWSDynamoDBObjectMapper.default()
        // We create a task that will save the user to DynamoDB
        // This works because AMZUser extends AWSDynamoDBObjectModel and conforms to AWSDynamoDBModeling
        let saveToDynamoDBTask: AWSTask = mapper.save(user)
        
        // If there is no imageData we only have to save to DynamoDB
        if user.imageData == nil {
            saveToDynamoDBTask.continue({ (task) -> AnyObject? in
                completion(task.error as NSError?)
                return nil
            })
        } else {
            // We have to save data to DynamoDB, and the image to S3
            saveToDynamoDBTask.continue(successBlock: { (task) -> AnyObject? in
                // An example of the AWSTask api. We return a task and continueWithBlock is called on this task.
                return self.createUploadImageTask(user)
            }).continue({ (task) -> AnyObject? in
                completion(task.error as NSError?)
                return nil
            })
        }
        
    }
    
    fileprivate func createUploadImageTask(_ user: UserData) -> AWSTask<AnyObject> {
        guard let userId = user.userId else {
            preconditionFailure("You should provide a user object with a userId when uploading a user image")
        }
        guard let imageData = user.imageData else {
            preconditionFailure("You are trying to create an UploadImageTask, but the user has no imageData")
        }
        
        // Save the image as a file. The filename is the userId
        let fileName = "\(userId).jpg"
        let fileURL = deviceDirectoryForUploads!.appendingPathComponent(fileName)
        do {
            try imageData.write(to: fileURL, options: .atomic)
        } catch let err {
            print("Error writing image to file: \(err.localizedDescription)")
        }
        
        // Create a task to upload the file
        let uploadRequest = AWSS3TransferManagerUploadRequest()!
        uploadRequest.body = fileURL
        uploadRequest.key = fileName
        uploadRequest.bucket = AMZConstants.S3BUCKET_USERS
        let transferManager = AWSS3TransferManager.default()!
        return transferManager.upload(uploadRequest)
    }
    
    fileprivate func createDownloadImageTask(_ userId: String) -> AWSTask<AnyObject> {
        
        // The location where the downloaded file has to be saved on the device
        let fileName = "\(userId).jpg"
        let fileURL = deviceDirectoryForDownloads!.appendingPathComponent(fileName)
        
        // Create a task to download the file
        let downloadRequest = AWSS3TransferManagerDownloadRequest()!
        downloadRequest.downloadingFileURL = fileURL
        downloadRequest.bucket = AMZConstants.S3BUCKET_USERS
        downloadRequest.key = fileName
        let transferManager = AWSS3TransferManager.default()!
        return transferManager.download(downloadRequest)
    }
    
}


// MARK: - RemoteService

extension AMZRemoteService: RemoteService {
    
    func createCurrentUser(_ userData: UserData? , completion: @escaping ErrorResultBlock ) {
        precondition(currentUser == nil, "currentUser should not exist when createCurrentUser(..) is called")
        precondition(userData == nil || userData!.userId == nil, "You can not create a user with a given userId. UserId's are assigned automatically")
        precondition(persistentUserId == nil, "A persistent userId should not yet exist")
        
        guard let identityProvider = identityProvider else {
            preconditionFailure("No identity provider available, did you forget to call configure() before using AMZRemoteService?")
        }
        
        // This covers the scenario that an app was deleted and later reinstalled. 
        // The goal is to create a new identity and a new user profile for this use case. 
        // By default, Cognito stores a Cognito identity in the keychain. 
        // This identity survives app uninstalls, so there can be an identity left from a previous app install. 
        // When we detect this scenario we remove all data from the keychain, so we can start from scratch.
        if identityProvider.identityId != nil {
            identityProvider.clearKeychain()
            assert(identityProvider.identityId == nil)
        }
        
        // Create a new Cognito identity
        let task: AWSTask = identityProvider.getIdentityId()
        task.continue({ (task) -> AnyObject? in
            if let error = task.error {
                completion(error as NSError?)
            } else {
                // The new cognito identity token is now stored in the keychain.
                // Create a new empty user object of type AMZUser
                var newUser = AMZUser()!
                // Copy the data from the parameter userData
                if let userData = userData {
                    newUser.updateWithData(userData)
                }
                // create a unique ID for the new user
                newUser.userId = NSUUID().uuidString
                // Now save the data on AWS. This will save the image on S3, the other data in DynamoDB
                self.saveAMZUser(newUser) { (error) -> Void in
                    if let error = error {
                        completion(error)
                    } else {
                        // Here we can be certain that the user was saved on AWS, so we set the local user instance
                        self.currentUser = newUser
                        self.persistentUserId = newUser.userId
                        completion(nil)
                    }
                }
            }
            return nil
        })
    }

    
    func updateCurrentUser(_ userData: UserData, completion: @escaping ErrorResultBlock) {
        guard var currentUser = currentUser else {
            preconditionFailure("currentUser should already exist when updateCurrentUser(..) is called")
        }
        precondition(userData.userId == nil || userData.userId == currentUser.userId, "Updating current user with a different userId is not allowed")
        precondition(persistentUserId != nil, "A persistent userId should exist")
        
        // create a new empty user
        var updatedUser = AMZUser()!
        // apply the new userData
        updatedUser.updateWithData(userData)
        // restore the userId of the current user
        updatedUser.userId = currentUser.userId
        
        // If there are no changes, there is no need to update.
        if updatedUser.isEqualTo(currentUser) {
            completion(nil)
            return
        }
        
        self.saveAMZUser(updatedUser) { (error) -> Void in
            if let error = error {
                completion(error)
            } else {
                // Here we can be certain that the user was saved on AWS, so we update the local user property
                currentUser.updateWithData(updatedUser)
                completion(nil)
            }
        }
    }
    
    
    func fetchCurrentUser(_ completion: @escaping UserDataResultBlock ) {
        precondition(persistentUserId != nil, "A persistent userId should exist")
        
        // Task to download the image
        let downloadImageTask: AWSTask = createDownloadImageTask(persistentUserId!)
        
        // Task to fetch the DynamoDB data
        let mapper = AWSDynamoDBObjectMapper.default()
        let loadFromDynamoDBTask: AWSTask = mapper.load(AMZUser.self, hashKey: persistentUserId!, rangeKey: nil)
        
        // Download the image
        downloadImageTask.continue({ (imageTask) -> AnyObject? in
            var didDownloadImage = false
            if let error = imageTask.error {
                // If there is an error we will ignore it, it's not fatal. Maybe there is no user image.
                print("Error downloading image: \(error)")
            } else {
                didDownloadImage = true
            }
            // Download the data from DynamoDB
            loadFromDynamoDBTask.continue({ (dynamoTask) -> AnyObject? in
                if let error = dynamoTask.error {
                    completion(nil, error as NSError?)
                } else {
                    if let user = dynamoTask.result as? AMZUser {
                        if didDownloadImage {
                            let fileName = "\(self.persistentUserId!).jpg"
                            let fileURL = self.deviceDirectoryForDownloads!.appendingPathComponent(fileName)
                            do {
                                try user.imageData = Data(contentsOf: fileURL)
                            } catch let err {
                                completion(nil, err as NSError?)
                                return nil
                            }
                        }
                        if var currentUser = self.currentUser {
                            currentUser.updateWithData(user)
                        } else {
                            self.currentUser = user
                        }
                        completion(user, nil)
                    } else {
                        // should probably never happen
                        assertionFailure("No userData and no error, why?")
                        completion(nil, nil)
                    }
                }
                return nil
            })
            return nil
        })
    }
    
}

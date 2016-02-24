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
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "userId")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey("userId")
        }
    }
    
    private (set) var identityProvider: AWSCognitoCredentialsProvider?
    
    private var deviceDirectoryForUploads: NSURL?
    
    private var deviceDirectoryForDownloads: NSURL?
    
    private static var sharedInstance: AMZRemoteService?
    
    // MARK: - Lifecycle
    
    init() {}
    
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
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        deviceDirectoryForUploads = createLocalTmpDirectory("upload")
        deviceDirectoryForDownloads = createLocalTmpDirectory("download")
    }

    
    private func createLocalTmpDirectory(let directoryName: String) -> NSURL? {
        do {
            let url = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(directoryName)
            try
                NSFileManager.defaultManager().createDirectoryAtURL(
                    url,
                    withIntermediateDirectories: true,
                    attributes: nil)
            return url
        } catch let error as NSError {
            print("Creating \(directoryName) directory failed. Error: \(error)")
            return nil
        }
    }
    
    
    func saveAMZUser(user: AMZUser, completion: ErrorResultBlock)  {
        precondition(user.userId != nil, "You should provide a user object with a userId when saving a user")
        
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let saveToDynamoDBTask: AWSTask = mapper.save(user)
        
        if user.imageData == nil {
            saveToDynamoDBTask.continueWithBlock({ (task) -> AnyObject? in
                completion(error: task.error)
                return nil
            })
        } else {
            saveToDynamoDBTask.continueWithSuccessBlock({ (task) -> AnyObject? in
                return self.createUploadImageTask(user)
            }).continueWithBlock({ (task) -> AnyObject? in
                completion(error: task.error)
                return nil
            })
        }
            
    }
    

    private func createUploadImageTask(user: UserData) -> AWSTask {
        guard let userId = user.userId else {
            preconditionFailure("You should provide a user object with a userId when uploading a user image")
        }
        guard let imageData = user.imageData else {
            preconditionFailure("You are trying to create an UploadImageTask, but the user has no imageData")
        }
        
        // Save the image as a file. The filename is
        let fileName = "\(userId).png"
        let fileURL = deviceDirectoryForUploads!.URLByAppendingPathComponent(fileName)
        imageData.writeToFile(fileURL.path!, atomically: true)
        
        // Create a task to upload the file
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.body = fileURL
        uploadRequest.key = fileName
        uploadRequest.bucket = AMZConstants.S3BUCKET_USERS
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        return transferManager.upload(uploadRequest)
    }
    
    private func createDownloadImageTask(userId: String) -> AWSTask {
        
        // The location where the downloaded file has to be saved on the device
        let fileName = "\(userId).png"
        let fileURL = deviceDirectoryForDownloads!.URLByAppendingPathComponent(fileName)
        
        // Create a task to download the file
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.downloadingFileURL = fileURL
        downloadRequest.bucket = AMZConstants.S3BUCKET_USERS
        downloadRequest.key = fileName
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        return transferManager.download(downloadRequest)
    }


    
}


// MARK: - RemoteService

extension AMZRemoteService: RemoteService {
    
    func createCurrentUser(userData: UserData? , completion: ErrorResultBlock ) {
        precondition(currentUser == nil, "currentUser should not exist when createCurrentUser(..) is called")
        precondition(userData == nil || userData!.userId == nil, "You can not create a user with a given userId. UserId's are assigned automatically")
        precondition(persistentUserId == nil, "A persistent userId should not yet exist")
        
        guard let identityProvider = identityProvider else {
            preconditionFailure("No identity provider available, did you forget to call configure() before using AMZRemoteService?")
        }
        
        // This covers the scenario that an app was deleted and later reinstalled. The goal is to create a new identity and a new user profile for this use case. By default, Cognito stores a Cognito identity in the keychain. This identity survives app uninstalls, so there can be an identity left from a previous app install. When we detect this scenario we remove all data from the keychain, so we can start from scratch.
        if identityProvider.identityId != nil {
            identityProvider.clearKeychain()
            assert(identityProvider.identityId == nil)
        }
        
        // Create a new Cognito identity
        let task: AWSTask = identityProvider.getIdentityId()
        task.continueWithBlock { (task) -> AnyObject? in
            if let error = task.error {
                completion(error: error)
            } else {
                // The new cognito identity token is now stored in the keychain.
                // Create a new empty user object of type AMZUser
                var newUser = AMZUser()
                // Copy the data from the parameter userData
                if let userData = userData {
                    newUser.updateWithData(userData)
                }
                // create a unique ID for the new user
                newUser.userId = NSUUID().UUIDString
                // Now save the data on AWS. This will save the image on S3, the other data in DynamoDB
                self.saveAMZUser(newUser) { (error) -> Void in
                    if let error = error {
                        completion(error: error)
                    } else {
                        // Here we can be certain that the user was saved on AWS, so we set the local user instance
                        self.currentUser = newUser
                        self.persistentUserId = newUser.userId
                        completion(error: nil)
                    }
                }
            }
            return nil
        }
    }

    
    func updateCurrentUser(userData: UserData, completion: ErrorResultBlock) {
        guard var currentUser = currentUser else {
            preconditionFailure("currentUser should already exist when updateCurrentUser(..) is called")
        }
        precondition(userData.userId == nil || userData.userId == currentUser.userId, "Updating current user with a different userId is not allowed")
        precondition(persistentUserId != nil, "A persistent userId should exist")
        
        // create a new empty user
        var updatedUser = AMZUser()
        // apply the new userData
        updatedUser.updateWithData(userData)
        // restore the userId of the current user
        updatedUser.userId = currentUser.userId
        
        if updatedUser.isEqualTo(currentUser) {
            return
        }
        
        self.saveAMZUser(updatedUser) { (error) -> Void in
            if let error = error {
                completion(error: error)
            } else {
                // Here we can be certain that the user was saved on AWS, so we update the local user instance.
                currentUser.updateWithData(updatedUser)
                completion(error: nil)
            }
        }
    }
    
    
    func fetchCurrentUser(completion: UserDataResultBlock ) {
        precondition(persistentUserId != nil, "A persistent userId should exist")
        
        // Task to download the image
        let downloadImageTask: AWSTask = createDownloadImageTask(persistentUserId!)
        
        // Task to fetch the DynamoDB data
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let loadFromDynamoDBTask: AWSTask = mapper.load(AMZUser.self, hashKey: persistentUserId!, rangeKey: nil)
        
        // Download the image
        downloadImageTask.continueWithBlock { (imageTask) -> AnyObject? in
            var didDownloadImage = false
            if let error = imageTask.error {
                // If there is an error we will ignore it, it's not fatal. Maybe there is no user image.
                print("Error downloading image: \(error)")
            } else {
                didDownloadImage = true
                print(imageTask.result) // is nil in the case of an error
            }
            // Download the data from DynamoDB
            loadFromDynamoDBTask.continueWithBlock({ (dynamoTask) -> AnyObject? in
                if let error = dynamoTask.error {
                    completion(userData: nil, error: error)
                } else {
                    if let user = dynamoTask.result as? AMZUser {
                        if didDownloadImage {
                            let fileName = "\(self.currentUser!.userId!).png"
                            let fileURL = self.deviceDirectoryForDownloads!.URLByAppendingPathComponent(fileName)
                            user.imageData = NSData(contentsOfURL: fileURL)
                        }
                        if var currentUser = self.currentUser {
                            currentUser.updateWithData(user)
                        } else {
                            self.currentUser = user
                        }
                        completion(userData: user, error: nil)
                    } else {
                        // should probably never happen
                        completion(userData: nil, error: nil)
                    }
                }
                return nil
            })
            return nil
        }
    }
    
}
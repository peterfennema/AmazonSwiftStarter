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

    private (set) var currentUser: UserData?
    
    // MARK: - Properties

    private var persistentUserId: String? {
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "userId")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey("userId")
        }
    }
    
    private var identityProvider: AWSCognitoCredentialsProvider?
    
    private var deviceDirectoryForUploads: NSURL?
    
    private var deviceDirectoryForDownloads: NSURL?
    
    private static var sharedInstance: AMZRemoteService?
    
    // MARK: - Lifecycle
    
    private init() {}
    
    // MARK: - Functions
    
    static func defaultService() -> RemoteService {
        if sharedInstance == nil {
            sharedInstance = AMZRemoteService()
            sharedInstance!.configure()
        }
        return sharedInstance!
    }
    
    private func configure() {
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
    
    
    private func saveAMZUser(user: AMZUser, completion: UserDataResultBlock)  {
        precondition(user.userId != nil, "You should provide a user object with a userId when saving a user")
        
        // Uploading the user image and saving the other user data are done in parallel, we will store all parallel tasks in this array.
        var allTasks = [AWSTask]()
        
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let saveToDynamoDBTask: AWSTask = mapper.save(user)
        allTasks.append(saveToDynamoDBTask)

        // If there is an image create a task to save it to S3
        if user.imageData != nil, let task = createUploadImageTask(user) {
            allTasks.append(task)
        }

        // Execute all tasks in parallel
        AWSTask(forCompletionOfAllTasksWithResults: allTasks).continueWithBlock { (task) -> AnyObject? in
            if let error = task.error {
                completion(userData: nil, error: error)
            } else {
                // TODO: Return the data that is really stored on the server, instead of the user 
                // TODO: Avoid the situation that there is no error and no userdata by returning an own error type
                completion(userData: user, error: nil)
            }
            return nil
        }
    }

    private func createUploadImageTask(user: UserData) -> AWSTask? {
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
    
    func createCurrentUser(userData: UserData? , completion: UserDataResultBlock ) {
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
                completion(userData: nil, error: error)
            } else {
                // The new cognito identity token is now stored in the keychain.
                // Create a new empty user object
                let newUser = AMZUser()
                // Copy the data from the parameter userData
                if let userData = userData {
                    newUser.updateWithData(userData)
                }
                // create a unique ID for the new user
                newUser.userId = NSUUID().UUIDString
                // Now save the data on AWS. This will save the image on S3, the other data in DynamoDB
                self.saveAMZUser(newUser) { (awsUserData, error) -> Void in
                    if let error = error {
                        completion(userData: nil, error: error)
                    } else {
                        // here we can be certain that the user was saved on AWS, so we update the local user instance
                        // There was no error, so we are guarantueed to have a awsUserData
                        let awsUserData = awsUserData!
                        self.currentUser = awsUserData
                        self.persistentUserId = awsUserData.userId
                        completion(userData: awsUserData, error: nil)
                     }
                }
            }
            return nil
        }
    }

    
    func updateCurrentUser(userData: UserData, completion: UserDataResultBlock) {
        guard let currentUser = currentUser else {
            preconditionFailure("currentUser should already exist when updateCurrentUser(..) is called")
        }
        precondition(userData.userId == nil || userData.userId == currentUser.userId, "Updating current user with a different userId is not allowed")
        
        // create a new empty user
        let amzUser = AMZUser()
        // copy the existing data of the current user
        amzUser.updateWithData(currentUser)
        // 
        amzUser.updateWithData(userData)
        self.saveAMZUser(amzUser) { (awsUserData, error) -> Void in
            if let error = error {
                completion(userData: nil, error: error)
            } else {
                // here we can be certain that the user was saved on AWS, so we update the local user instance
                // There was no error, so we are guarantueed to have a awsUserData
                let awsUserData = awsUserData!
                self.currentUser!.updateWithData(awsUserData)
                completion(userData: awsUserData, error: nil)
            }
        }
    }
    
    func fetchCurrentUser(completion: UserDataResultBlock ) {
        assert(persistentUserId != nil)
        let downloadImageTask: AWSTask = createDownloadImageTask(persistentUserId!)
        
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let loadFromDynamoDBTask: AWSTask = mapper.load(AMZUser.self, hashKey: persistentUserId!, rangeKey: nil)
        
        let allTasks = [downloadImageTask, loadFromDynamoDBTask]
        AWSTask(forCompletionOfAllTasksWithResults: allTasks).continueWithBlock { (task) -> AnyObject? in
            if let error = task.error {
                completion(userData: nil, error: error)
                return nil
            } else {
                if let tasks = task.result, let userData = tasks[1] as? AMZUser {
                    if self.currentUser == nil {
                        self.currentUser = userData
                    } else {
                        self.currentUser!.updateWithData(userData)
                    }
                    let fileName = "\(self.currentUser!.userId!).png"
                    let fileURL = self.deviceDirectoryForDownloads!.URLByAppendingPathComponent(fileName)
                    self.currentUser!.imageData = NSData(contentsOfURL: fileURL)
                    completion(userData: self.currentUser!, error: nil)
                }
                return nil
            }
        }
    }
    
}
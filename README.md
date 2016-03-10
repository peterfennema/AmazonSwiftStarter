# AmazonSwiftStarter
A demo app for iOS developers who are considering to use Amazon Web Services (AWS) as a backend. The app is written in Swift and uses the AWS iOS SDK.

I am looking for a replacement of Parse. My most important goal is to research the features I need for my commercial app, and prototype them in this demo app.

## Version 3.0 (for blog post 3)
http://peterfennema.nl/exploring-aws-as-a-backend-for-a-swift-app-3/

This version of the app accesses AWS. It uses the following services: Cognito, DynamoDB, S3, IAM

## Version 1.0 (for blog post 1)
http://peterfennema.nl/exploring-aws-as-a-backend-for-a-swift-app-1/

The app will let a user sign up anonymously, and let him/her create a profile. The profile consists of his/her name and a photo. 

This version of the app is prepared to access AWS, but in reality it does not yet access AWS at all. Instead it uses a simulated backend. 

Example of a clean separation between the backend logic and the other code of the app. This clean separation makes it easier to change backend providers if needed 😉
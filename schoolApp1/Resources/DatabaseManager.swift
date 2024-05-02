//
//  DatabaseManager.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 5/20/23.
//

//TODO: Memory leaks and security issues, good comments/documentation too, deleting convos, logging in & out issues with sessions (dean vs student capabilities)
//TODO: Mystery errors ("Error nil") and failedToVerify's when cycling through accounts, but still works fine????
//TODO: Simulaneous Database writes???!!!
//TODO: If you create a convo, latest msg should be read
//TODO: Rendering error when deleting a convo
//TODO: Change user convo list to be a dict like main convo list in database
import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation
//TODO: Sorting/adding folders to database for neater appearance
///Manager object to read and write data to real time firebase database
final class DatabaseManager {
    ///Shared instance of class
    public static let shared = DatabaseManager()
    private static var sessionProvided: Bool = false
    private let database = Database.database().reference()
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    static func formatNames(names: [String]) -> String {
        var namesString = ""
        if names.isEmpty {
            return ""
        }
        else if names.count > 2 {
            namesString = "\(names[0]), \(names[1]) + \(names.count - 2) more"
        }
        else {
            for index in 0...names.count - 1 {
                namesString += "\(names[index])"
                if index != names.count - 1 {
                    namesString += ", "
                }
            }
        }
        return namesString
    }
    
    static func formatGrade(grade: Int) -> String {
        if grade == 9 {
            return "Freshman"
        }
        else if grade == 10 {
            return "Sophomore"
        }
        else if grade == 11 {
            return "Junior"
        }
        else if grade == 12 {
            return "Senior"
        }
        else {
            return "Unknown"
        }
    }
}

extension DatabaseManager {
    /// Returns dictionary node at child path
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

//MARK: - Account Management
extension DatabaseManager {
    /// Checks if user exists for given email
    /// Parameters
    /// - `email`:              Target email to be checked
    /// - `completion`:   Async closure to return with result
    
    public func userExists(with email: String, completion: @escaping((Bool) -> Void)) {
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName,
            "display_name": user.displayName as Any,
            "is_dean": user.isDean,
            "grade": user.grade as Any
        ], withCompletionBlock: { [weak self] error, _ in
            
            guard let strongSelf = self else {return}
            
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            strongSelf.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String?]] {
                    //append to user dictionary
                    let newElement = [
                        "first_name": user.firstName,
                        "last_name": user.lastName,
                        "display_name": user.displayName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    strongSelf.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                else {
                    //create that array
                    let newCollection: [[String: String?]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "display_name": user.displayName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    strongSelf.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            print(error as Any)
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
        })
    }
    
    /// Gets all users from database
    public func getAllUsers(completion: @escaping (Result<[[String: String?]], Error>) -> Void) {
        verifyDean(completion: { [weak self] success in
            guard success, let strongSelf = self else {
                completion(.failure(DatabaseError.failedToVerify))
                return
            }
            
            strongSelf.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                guard let value = snapshot.value as? [[String: String?]] else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(value))
            })
        })
    }
    
    public func changeDisplayName(to newName: String?, completion: @escaping (Bool) -> Void) {
        verifyDean(completion: { [weak self] success in
            guard success, let strongSelf = self, let currentName = UserDefaults.standard.value(forKey: "name") as? String, let currentFirstName = UserDefaults.standard.value(forKey: "first_name") as? String, let currentLastName = UserDefaults.standard.value(forKey: "last_name") as? String,
                  let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
            
            let currentDisplayName = UserDefaults.standard.value(forKey: "display_name") as? String ?? currentName
            
            strongSelf.database.child("\(safeEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                if let conversations = snapshot.value as? [[String: Any]] {
                    var otherUserEmails: [String] = []
                    for conversation in conversations {
                        guard let otherConversationEmails = conversation["other_user_emails"] as? [String] else {return}
                        otherUserEmails.append(contentsOf: otherConversationEmails)
                    }
                    otherUserEmails = Array(Set(otherUserEmails))
                    
                    for otherUserEmail in otherUserEmails {
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            guard var otherConversations = snapshot.value as? [[String: Any]] else {return}
                            for index in 0...otherConversations.count - 1 {
                                guard var otherConversationUserNames = otherConversations[index]["other_user_names"] as? [String] else {return}
                                otherConversationUserNames.removeAll(where: {$0 == currentDisplayName})
                                otherConversationUserNames.append(newName ?? currentName)
                                otherConversations[index].updateValue(otherConversationUserNames, forKey: "other_user_names")
                                otherConversations[index].updateValue(DatabaseManager.formatNames(names: otherConversationUserNames), forKey: "conversation_name")
                            }
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherConversations, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    print("Failed to write to database")
                                    completion(false)
                                    return
                                }
                            })
                        })
                    }
                    strongSelf.database.child("\(safeEmail)").observeSingleEvent(of: .value, with: { snapshot in
                        guard var userInfo = snapshot.value as? [String: Any] else {
                            completion(false)
                            return
                        }
                        userInfo.updateValue(newName as Any, forKey: "display_name")
                        strongSelf.database.child("\(safeEmail)").setValue(userInfo, withCompletionBlock: { error, _ in
                            
                            guard error == nil else {
                                print("Failed to write to database")
                                completion(false)
                                return
                            }
                        })
                    })
                }
                else {
                    strongSelf.database.child("\(safeEmail)").observeSingleEvent(of: .value, with: { snapshot in
                        guard var userInfo = snapshot.value as? [String: Any] else {
                            completion(false)
                            return
                        }
                        userInfo.updateValue(newName as Any, forKey: "display_name")
                        strongSelf.database.child("\(safeEmail)").setValue(userInfo, withCompletionBlock: { error, _ in
                            
                            guard error == nil else {
                                print("Failed to write to database")
                                completion(false)
                                return
                            }
                        })
                    })
                }
                strongSelf.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                    
                    guard var usersCollection = snapshot.value as? [[String: String?]] else {
                        completion(false)
                        return
                    }
                    //append to user dictionary
                    let changedElement = [
                        "first_name": currentFirstName,
                        "last_name": currentLastName,
                        "display_name": newName,
                        "email": safeEmail
                    ]
                    usersCollection.removeAll(where: {$0["email"] == safeEmail})
                    usersCollection.append(changedElement)
                    strongSelf.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            print(error as Any)
                            completion(false)
                            return
                        }
                        strongSelf.database.child("announcement_grades").observeSingleEvent(of: .value, with: { snapshot in
                            
                            guard let announcementGradesCollection = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            
                            var newAnnouncementGrades: [[String: Any]] = []
                            
                            for announcementGrade in announcementGradesCollection {
                                var newAnnouncementGrade: [String: Any] = announcementGrade
                                guard let announcements = announcementGrade["announcements"] as? [[String: Any]], var latestAnnouncement = announcementGrade["latest_announcement"] as? [String: Any], let latestAnnouncementSenderEmail = latestAnnouncement["sender_email"] as? String else {
                                    completion(false)
                                    return
                                }
                                
                                var newAnnouncements: [[String: Any]] = []
                                for announcement in announcements {
                                    guard let senderEmail = announcement["sender_email"] as? String else {
                                        completion(false)
                                        return
                                    }
                                    var newAnnouncement = announcement
                                    if senderEmail == safeEmail {
                                        newAnnouncement.updateValue(newName ?? currentName, forKey: "sender_name")
                                    }
                                    newAnnouncements.append(newAnnouncement)
                                }
                                
                                if latestAnnouncementSenderEmail == safeEmail {
                                    latestAnnouncement.updateValue(newName ?? currentName, forKey: "sender_name")
                                }
                                
                                newAnnouncementGrade.updateValue(newAnnouncements, forKey: "announcements")
                                newAnnouncementGrade.updateValue(latestAnnouncement, forKey: "latest_announcement")
                                
                                newAnnouncementGrades.append(newAnnouncementGrade)
                            }
                            
                            strongSelf.database.child("announcement_grades").setValue(newAnnouncementGrades, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    print(error as Any)
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
            })
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
        case failedToVerify
        
        public var localizedDescription: String {
            switch self {
            case .failedToFetch:
                return "This error means that the retrieval of data from the database or client failed"
            case .failedToVerify:
                return "This error means that the verification of the user's session or status failed"
            }
        }
    }
    
    /*
     users => [
     [
     "name":
     "safe_email":
     ]
     [
     "name":
     "safe_email":
     ]
     ]
     */
}

//MARK: - Authentication and Verification
extension DatabaseManager {
    public func provideSession(for userEmail: String, completion: (() -> Void)?) {
        if !DatabaseManager.sessionProvided {
            DatabaseManager.sessionProvided = true
            let safeEmail = DatabaseManager.safeEmail(emailAddress: userEmail)
            let newSessionID = generateSessionID()
            database.child("\(safeEmail)/session_id").setValue(newSessionID, withCompletionBlock: { error, _ in
                guard error == nil else {
                    print(error as Any)
                    fatalError("Failed to create new session")
                }
                UserDefaults.standard.set(newSessionID, forKey: "session_id")
                completion?()
            })
        }
        else {
            completion?()
        }
    }
    
    private func generateSessionID() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map{ _ in characters.randomElement()!})
    }
    
    public func endSession(completion: @escaping () -> Void) {
        UserDefaults.standard.set(nil, forKey: "session_id")
        DatabaseManager.sessionProvided = false
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        database.child("\(safeEmail)/session_id").setValue(nil, withCompletionBlock: { error, _ in
            if error != nil {
                print(error as Any)
                print("Failed to end session properly")
            }
            completion()
        })
    }
    
    public func verifySession(completion: @escaping (Bool) -> Void) {
        guard let userEmail = UserDefaults.standard.value(forKey: "email") as? String, let currentSessionID = UserDefaults.standard.value(forKey: "session_id") as? String else {
            print("Session Verification Failed")
            completion(false)
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: userEmail)
        
        database.child("\(safeEmail)/session_id").observeSingleEvent(of: .value, with: { snapshot in
            guard let userSessionID = snapshot.value as? String else {
                print("Session Verification Failed")
                completion(false)
                return
            }
            
            if currentSessionID == userSessionID {
                print("Session Verification Successful")
                completion(true)
            }
            else {
                print("Session Verification Failed")
                completion(false)
            }
        })
    }
    
    public func verifyDean(completion: @escaping (Bool) -> Void) {
        verifySession(completion: { [weak self] success in
            guard success, let strongSelf = self, let userEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                print("Status Verification Failed")
                completion(false)
                return
            }
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: userEmail)
            
            strongSelf.database.child("\(safeEmail)/is_dean").observeSingleEvent(of: .value, with: { snapshot in
                guard let isDean = snapshot.value as? Bool else {
                    print("Status Verification Failed")
                    completion(false)
                    return
                }
                
                if isDean {
                    print("Status Verification Successful")
                    completion(true)
                }
                else {
                    print("Status Verification Failed")
                    completion(false)
                }
            })
        })
    }
}

// MARK: - Messages and Conversations
extension DatabaseManager {
    /*
     "dfsdfdsfds" {
     "messages": [{
     "id": String,
     "type": text, photo, video,
     "content": String,
     "date": Date(),
     "sender_email": String,
     "isRead": true/false,
     }
     ]
     }
     
     conversation => [
     [
     "conversation_id": "dfsdfdsfds"
     "other_user_email":
     "latest_message": => {
     "date": Date()
     "latest_message": "message"
     "is_read": true/false
     }
     ],
     ]
     */
    
    //MARK: Change this to create new conversation with multiple other names
    /// Creates a new conversation with target user emails and first message sent
    public func createNewConversation(with otherUserEmails: [String], otherUserNames: [String], firstMessage: Message, completion: @escaping (Bool) -> Void) {
        verifyDean(completion: { [weak self] success in
            guard success, let strongSelf = self, let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
                  var currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                completion(false)
                return
            }
            
            if let displayName = UserDefaults.standard.value(forKey: "display_name") as? String {
                currentName = displayName
            }
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
            
            var allUserEmails = otherUserEmails
            allUserEmails.append(safeEmail)
            
            let ref = strongSelf.database.child("\(safeEmail)")
            
            ref.observeSingleEvent(of: .value, with: { snapshot in
                guard var userNode = snapshot.value as? [String: Any] else {
                    completion(false)
                    print("User not found")
                    return
                }
                
                let messageDate = firstMessage.sentDate
                let dateString = ChatViewController.dateFormatter.string(from: messageDate)
                
                var message = ""
                
                switch firstMessage.kind {
                    
                case .text(let messageText):
                    message = messageText
                case .attributedText(_):
                    break
                case .photo(_):
                    break
                case .video(_):
                    break
                case .location(_):
                    break
                case .emoji(_):
                    break
                case .audio(_):
                    break
                case .contact(_):
                    break
                case .custom(_), .linkPreview(_):
                    break
                }
                
                let conversationId = "conversation_\(firstMessage.messageId)"
                
                let latestMessage: [String: Any] = [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
                
                let newConversationData: [String: Any] = [
                    "id": conversationId,
                    "other_user_emails": otherUserEmails,
                    "other_user_names": otherUserNames,
                    "conversation_name": DatabaseManager.formatNames(names: otherUserNames),
                    "latest_message": latestMessage
                ]
                //Update recipient conversation entry
                
                for index in 0...otherUserEmails.count - 1 {
                    let recipientEmail = otherUserEmails[index]
                    let recipientName = otherUserNames[index]
                    
                    var otherEmailsExcludingRecipient: [String] = []
                    otherEmailsExcludingRecipient.append(safeEmail)
                    for otherEmail in otherUserEmails {
                        if otherEmail != recipientEmail {
                            otherEmailsExcludingRecipient.append(otherEmail)
                        }
                    }
                    
                    var otherNamesExcludingRecipient: [String] = []
                    otherNamesExcludingRecipient.append(currentName)
                    for otherName in otherUserNames {
                        if otherName != recipientName {
                            otherNamesExcludingRecipient.append(otherName)
                        }
                    }
                    
                    let recipientNewConversationData: [String: Any] = [
                        "id": conversationId,
                        "other_user_emails": otherEmailsExcludingRecipient,
                        "other_user_names": otherNamesExcludingRecipient,
                        "conversation_name": DatabaseManager.formatNames(names: otherNamesExcludingRecipient),
                        "latest_message": latestMessage
                    ]
                    
                    strongSelf.database.child("\(recipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                        if var conversations = snapshot.value as? [[String: Any]] {
                            //append
                            conversations.append(recipientNewConversationData)
                            strongSelf.database.child("\(recipientEmail)/conversations").setValue(conversations)
                        }
                        else {
                            //create
                            strongSelf.database.child("\(recipientEmail)/conversations").setValue([recipientNewConversationData])
                        }
                    })
                }
                //Update current user conversation entry
                if var conversations = userNode["conversations"] as? [[String: Any]] {
                    // conversation array exists for current user
                    // you should append
                    
                    conversations.append(newConversationData)
                    userNode["conversations"] = conversations
                    ref.setValue(userNode, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        strongSelf.finishCreatingConversation(conversationID: conversationId, userEmails: allUserEmails, firstMessage: firstMessage, completion: completion)
                    })
                }
                else {
                    // conversation array does NOT exist
                    // create it
                    userNode["conversations"] = [
                        newConversationData
                    ]
                    
                    ref.setValue(userNode, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        strongSelf.finishCreatingConversation(conversationID: conversationId, userEmails: allUserEmails, firstMessage: firstMessage, completion: completion)
                    })
                }
            })
        })
    }
    
    private func finishCreatingConversation(conversationID: String, userEmails: [String], firstMessage: Message, completion: @escaping (Bool) -> Void) {
        //        {
        //            "id": String,
        //            "type": text, photo, video,
        //            "content": String,
        //            "date": Date(),
        //            "sender_email": String,
        //            "isRead": true/false,
        //        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_), .photo(_), .video(_), .location(_), .emoji(_), .audio(_), .contact(_), .custom(_), .linkPreview(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String,
              var currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            completion(false)
            return
        }
        
        if let displayName = UserDefaults.standard.value(forKey: "display_name") as? String {
            currentName = displayName
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentEmail,
            "sender_name": currentName,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "user_emails": userEmails,
            "messages": [
                collectionMessage
            ]
        ]
        
        print("Adding conversation: \(conversationID)")
        
        database.child("conversations/\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        verifySession(completion: { [weak self] success in
            guard success, let strongSelf = self else {
                completion(.failure(DatabaseError.failedToVerify))
                return
            }
            strongSelf.database.child("\(email)/conversations").observe(.value, with: { snapshot in
                guard let value = snapshot.value as? [[String: Any]] else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                let conversations: [Conversation] = value.compactMap({ dictionary in
                    guard let conversationId = dictionary["id"] as? String, let conversationName = dictionary["conversation_name"] as? String, let otherUserEmails = dictionary["other_user_emails"] as? [String], let otherUserNames = dictionary["other_user_names"] as? [String], let latestMessage = dictionary["latest_message"] as? [String: Any], let date = latestMessage["date"] as? String, let message = latestMessage["message"] as? String, let isRead = latestMessage["is_read"] as? Bool else {
                        return nil
                    }
                    
                    let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                    return Conversation(id: conversationId, conversationName: conversationName, otherUserEmails: otherUserEmails, otherUserNames: otherUserNames, latestMessage: latestMessageObject)
                })
                completion(.success(conversations))
            })
        })
    }
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        verifySession(completion: { [weak self] success in
            guard success, let strongSelf = self else {
                completion(.failure(DatabaseError.failedToVerify))
                return
            }
            strongSelf.database.child("conversations/\(id)/messages").observe(.value, with: { snapshot in
                guard let value = snapshot.value as? [[String: Any]] else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                let messages: [Message] = value.compactMap({ dictionary in
                    guard let senderName = dictionary["sender_name"] as? String,
                          let isRead = dictionary["is_read"] as? Bool,
                          let messageID = dictionary["id"] as? String,
                          let content = dictionary["content"] as? String,
                          let senderEmail = dictionary["sender_email"] as? String,
                          let type = dictionary["type"] as? String,
                          let dateString = dictionary["date"] as? String,
                          let date = ChatViewController.dateFormatter.date(from: dateString) else {
                        return nil
                    }
                    var kind: MessageKind?
                    if type == "photo" {
                        // photo
                        guard let imageUrl = URL(string: content),
                              let placeHolder = UIImage(systemName: "photo") else {
                            return nil
                        }
                        let media = Media(url: imageUrl,
                                          image: nil,
                                          placeholderImage: placeHolder,
                                          size: CGSize(width: 300, height: 300))
                        kind = .photo(media)
                    }
                    else if type == "video" {
                        // video
                        guard let videoUrl = URL(string: content),
                              let placeHolder = UIImage(systemName: "display") else {
                            return nil
                        }
                        
                        let media = Media(url: videoUrl,
                                          image: nil,
                                          placeholderImage: placeHolder,
                                          size: CGSize(width: 300, height: 300))
                        kind = .video(media)
                    }
                    else if type == "location" {
                        let locationComponents = content.components(separatedBy: ",")
                        guard let latitude = Double(locationComponents[0]),
                              let longitude = Double(locationComponents[1]) else {
                            return nil
                        }
                        print("Rendering location: long = \(longitude) | lat = \(latitude)")
                        let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                                size: CGSize(width: 300, height: 300))
                        kind = .location(location)
                    }
                    else {
                        kind = .text(content)
                    }
                    
                    guard let finalKind = kind else {
                        return nil
                    }
                    
                    let sender = Sender(photoURL: "",
                                        senderId: senderEmail,
                                        displayName: senderName)
                    
                    return Message(sender: sender,
                                   messageId: messageID,
                                   sentDate: date,
                                   kind: finalKind)
                })
                
                completion(.success(messages))
            })
        })
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, otherUserEmails: [String], otherUserNames: [String], newMessage: Message, completion: @escaping (Bool) -> Void) {
        //add new message to messages
        //update sender latest message
        //update recipient latest message
        verifySession(completion: { [weak self] success in
            guard success, let strongSelf = self, let myEmail = UserDefaults.standard.value(forKey: "email") as? String,
                  let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                completion(false)
                return
            }
            
            let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            strongSelf.database.child("conversations/\(conversation)/messages").observeSingleEvent(of: .value, with: { snapshot in
                guard var currentMessages = snapshot.value as? [[String: Any]] else {
                    completion(false)
                    return
                }
                
                let messageDate = newMessage.sentDate
                let dateString = ChatViewController.dateFormatter.string(from: messageDate)
                
                var message = ""
                switch newMessage.kind {
                case .text(let messageText):
                    message = messageText
                case .photo(let mediaItem):
                    if let targetUrlString = mediaItem.url?.absoluteString {
                        message = targetUrlString
                    }
                    break
                case .video(let mediaItem):
                    if let targetUrlString = mediaItem.url?.absoluteString {
                        message = targetUrlString
                    }
                    break
                case .location(let locationData):
                    let location = locationData.location
                    message = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                    break
                case .attributedText(_), .emoji(_), .audio(_), .contact(_), .custom(_), .linkPreview(_):
                    break
                }
                
                let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
                
                let newMessageEntry: [String: Any] = [
                    "id": newMessage.messageId,
                    "type": newMessage.kind.messageKindString,
                    "content": message,
                    "date": dateString,
                    "sender_email": currentUserEmail,
                    "sender_name": currentName,
                    "is_read": false
                ]
                
                currentMessages.append(newMessageEntry)
                
                strongSelf.database.child("conversations/\(conversation)/messages").setValue(currentMessages) {error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                        var databaseEntryConversations = [[String: Any]]()
                        let updatedValue: [String: Any] = [
                            "date": dateString,
                            "is_read": true,
                            "message": message
                        ]
                        var safeOtherEmails: [String] = []
                        for email in otherUserEmails {
                            safeOtherEmails.append(DatabaseManager.safeEmail(emailAddress: email))
                        }
                        if var currentUserConversations = snapshot.value as? [[String: Any]] {
                            var targetConversation: [String: Any]?
                            
                            var position = 0
                            
                            for conversationDictionary in currentUserConversations {
                                if let currentId = conversationDictionary["id"] as? String,
                                   currentId == conversation {
                                    targetConversation = conversationDictionary
                                    
                                    break
                                }
                                position += 1
                            }
                            
                            if var targetConversation = targetConversation {
                                targetConversation["latest_message"] = updatedValue
                                currentUserConversations[position] = targetConversation
                                databaseEntryConversations = currentUserConversations
                            }
                            else {
                                let newConversationData: [String: Any] = [
                                    "id": conversation,
                                    "other_user_emails": safeOtherEmails,
                                    "other_user_names": otherUserNames,
                                    "conversation_name": DatabaseManager.formatNames(names: otherUserNames),
                                    "latest_message": updatedValue
                                ]
                                currentUserConversations.append(newConversationData)
                                databaseEntryConversations = currentUserConversations
                            }
                        }
                        else {
                            let newConversationData: [String: Any] = [
                                "id": conversation,
                                "other_user_emails": safeOtherEmails,
                                "other_user_names": otherUserNames,
                                "conversation_name": DatabaseManager.formatNames(names: otherUserNames),
                                "latest_message": updatedValue
                            ]
                            databaseEntryConversations = [
                                newConversationData
                            ]
                        }
                        
                        strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: {error, _ in
                            guard error == nil else{
                                completion(false)
                                return
                            }
                            
                            // Update latest message for recipient user
                            
                            for index in 0...otherUserEmails.count - 1 {
                                let recipientEmail = otherUserEmails[index]
                                let recipientName = otherUserNames[index]
                                
                                var otherEmailsExcludingRecipient: [String] = []
                                otherEmailsExcludingRecipient.append(currentEmail)
                                for otherEmail in otherUserEmails {
                                    if otherEmail != recipientEmail {
                                        otherEmailsExcludingRecipient.append(otherEmail)
                                    }
                                }
                                
                                var otherNamesExcludingRecipient: [String] = []
                                otherNamesExcludingRecipient.append(currentName)
                                for otherName in otherUserNames {
                                    if otherName != recipientName {
                                        otherNamesExcludingRecipient.append(otherName)
                                    }
                                }
                                
                                strongSelf.database.child("\(recipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                                    var databaseEntryConversations = [[String: Any]]()
                                    let updatedValue: [String: Any] = [
                                        "date": dateString,
                                        "is_read": false,
                                        "message": message
                                    ]
                                    
                                    if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                        var targetConversation: [String: Any]?
                                        
                                        var position = 0
                                        
                                        for conversationDictionary in otherUserConversations {
                                            if let currentId = conversationDictionary["id"] as? String,
                                               currentId == conversation {
                                                targetConversation = conversationDictionary
                                                
                                                break
                                            }
                                            position += 1
                                        }
                                        if var targetConversation = targetConversation {
                                            targetConversation["latest_message"] = updatedValue
                                            otherUserConversations[position] = targetConversation
                                            databaseEntryConversations = otherUserConversations
                                        }
                                        else {
                                            // Failed to find in current collection
                                            let newConversationData: [String: Any] = [
                                                "id": conversation,
                                                "other_user_emails": otherEmailsExcludingRecipient,
                                                "other_user_names": otherNamesExcludingRecipient,
                                                "conversation_name": DatabaseManager.formatNames(names: otherNamesExcludingRecipient),
                                                "latest_message": updatedValue
                                            ]
                                            otherUserConversations.append(newConversationData)
                                            databaseEntryConversations = otherUserConversations
                                        }
                                    }
                                    else {
                                        // Current collection does not exist
                                        let newConversationData: [String: Any] = [
                                            "id": conversation,
                                            "other_user_emails": otherEmailsExcludingRecipient,
                                            "other_user_names": otherNamesExcludingRecipient,
                                            "conversation_name": DatabaseManager.formatNames(names: otherNamesExcludingRecipient),
                                            "latest_message": updatedValue
                                        ]
                                        databaseEntryConversations = [
                                            newConversationData
                                        ]
                                    }
                                    
                                    
                                    strongSelf.database.child("\(recipientEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: {error, _ in
                                        guard error == nil else{
                                            completion(false)
                                            return
                                        }
                                        completion(true)
                                    })
                                })
                            }
                        })
                    })
                }
            })
        })
    }
    
    public func updateLatestMessageIsRead(for conversation: String, completion: @escaping (Bool) -> Void) {
        verifySession(completion: { [weak self] success in
            guard success, let strongSelf = self, let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
            
            strongSelf.database.child("\(safeEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                guard var conversationsCollection = snapshot.value as? [[String: Any]] else {
                    completion(false)
                    return
                }
                
                for index in 0...conversationsCollection.count - 1 {
                    guard let conversationID = conversationsCollection[index]["id"] as? String else {
                        completion(false)
                        return
                    }
                    
                    if conversationID == conversation {
                        guard var updatedLatestMessage = conversationsCollection[index]["latest_message"] as? [String: Any] else {
                            completion(false)
                            return
                        }
                        
                        updatedLatestMessage.updateValue(true, forKey: "is_read")
                        conversationsCollection[index].updateValue(updatedLatestMessage, forKey: "latest_message")
                    }
                    strongSelf.database.child("\(safeEmail)/conversations").setValue(conversationsCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            print("Failed to write to database")
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
        })
    }
    
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
        verifyDean(completion: { [weak self] success in
            guard success, let strongSelf = self else {
                return
            }
            
            print("Deleting conversation with id: \(conversationId)")
            
            // Get all conversations for current user
            // delete conversation in collection with target id
            // reset those conversations for the user in database
            strongSelf.database.child("conversations/\(conversationId)").observeSingleEvent(of: .value, with: { snapshot in
                guard let conversation = snapshot.value as? [String : Any], let userEmails = conversation["user_emails"] as? [String] else {
                    completion(false)
                    return
                }
                strongSelf.finishRemovingConversation(for: userEmails, with: conversationId, completion: completion)
            })
        })
    }
    
    public func finishRemovingConversation(for userEmails: [String], with conversationId: String, completion: @escaping (Bool) -> Void) {
        let userEmail = userEmails[0]
        let ref = database.child("\(userEmail)/conversations")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self, var conversations = snapshot.value as? [[String: Any]] else {
                print("Failed to remove conversation from user")
                completion(false)
                return
            }
            var positionToRemove = 0
            var foundConversation = false
            while !foundConversation {
                let conversation = conversations[positionToRemove]
                if let id = conversation["id"] as? String, id == conversationId {
                    foundConversation = true
                }
                else {
                    positionToRemove += 1
                }
            }
            
            conversations.remove(at: positionToRemove)
            ref.setValue(conversations, withCompletionBlock: { error, _  in
                guard error == nil else {
                    print("Failed to remove conversation from user")
                    completion(false)
                    return
                }
                var nextUserEmails = userEmails
                nextUserEmails.removeFirst()
                if !nextUserEmails.isEmpty {
                    strongSelf.finishRemovingConversation(for: nextUserEmails, with: conversationId, completion: completion)
                }
                else {
                    strongSelf.database.child("conversations").observeSingleEvent(of: .value, with: { snapshot in
                        guard let oldConversations = snapshot.value as? [String : [String : Any]] else {
                            completion(false)
                            return
                        }
                        var newConversations = oldConversations
                        newConversations.removeValue(forKey: conversationId)
                        strongSelf.database.child("conversations").setValue(newConversations, withCompletionBlock: { error, _  in
                            guard error == nil else {
                                print("Failed to remove conversation data")
                                completion(false)
                                return
                            }
                            print("Successfully deleted conversation")
                            completion(true)
                        })
                    })
                }
            })
        })
    }
    
    public func conversationExists(with targetRecipientEmails: [String], completion: @escaping (Result<String, Error>) -> Void) {
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeSenderEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            // Iterate and find conversation with target sender
            if let conversation = collection.first(where: {
                guard let targetSenderEmails = $0["other_user_emails"] as? [String] else {
                    return false
                }
                return targetRecipientEmails.difference(from: targetSenderEmails).isEmpty
            }) {
                // Get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            
            completion(.failure(DatabaseError.failedToFetch))
            return
        })
    }
}

// MARK: - Announcements

extension DatabaseManager {
    public func createNewAnnouncementGrade(for grade: Int, completion: @escaping (Bool) -> Void) {
        verifyDean(completion: { [weak self] success in
            guard success, let strongSelf = self, let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
                  var currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                completion(false)
                return
            }
            
            if let displayName = UserDefaults.standard.value(forKey: "display_name") as? String {
                currentName = displayName
            }
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
            
            let newAnnouncementGrade = [[
                "grade": grade,
                "announcements": [[
                    "title": "Welcome!",
                    "body": "This is the \(DatabaseManager.formatGrade(grade: grade)) announcements page.",
                    "attachments": nil,
                    "grade": grade,
                    "sent_date": DatabaseManager.dateFormatter.string(from: Date().addingTimeInterval(-10)),
                    "sender_email": safeEmail,
                    "sender_name": currentName,
                    "announcement_id": "grade_\(grade)_announcement_\(safeEmail)_\(DatabaseManager.dateFormatter.string(from: Date().addingTimeInterval(-1)))",
                    "pinned": false
                ]],
                "latest_announcement": [
                    "sent_date": DatabaseManager.dateFormatter.string(from: Date().addingTimeInterval(-10)),
                    "title": "Welcome!",
                    "sender_name": currentName,
                    "sender_email": safeEmail
                ]]] as [[String: Any]]
            
            strongSelf.database.child("announcement_grades").observeSingleEvent(of: .value, with: { snapshot in
                strongSelf.database.child("announcement_grades").setValue(newAnnouncementGrade, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                })
                
                if var announcementGrades = snapshot.value as? [[String: Any]] {
                    var gradeIndex: Int = 0
                    
                    for index in 0...announcementGrades.count - 1 {
                        guard let compareGrade = announcementGrades[index]["grade"] as? Int else {
                            completion(false)
                            return
                        }
                        if compareGrade < grade {
                            gradeIndex = index + 1
                        }
                    }
                    
                    announcementGrades.insert(contentsOf: newAnnouncementGrade, at: gradeIndex)
                    strongSelf.database.child("announcement_grades").setValue(announcementGrades, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                    })
                }
                else {
                    strongSelf.database.child("announcement_grades").setValue(newAnnouncementGrade, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                    })
                }
                completion(true)
            })
        })
    }
    
    public func createNewAnnouncement(with newAnnouncement: Announcement, completion: @escaping (Bool) -> Void) {
        verifyDean(completion: { [weak self] success in
            guard success, let strongSelf = self else {
                completion(false)
                return
            }
            let newAnnouncementEntry = [
                "title": newAnnouncement.title,
                "body": newAnnouncement.body,
                "attachments": newAnnouncement.attachments as Any,
                "grade": newAnnouncement.grade,
                "sent_date": newAnnouncement.sentDate,
                "sender_email": newAnnouncement.senderEmail,
                "sender_name": newAnnouncement.senderName,
                "announcement_id": newAnnouncement.announcementId,
                "pinned": newAnnouncement.pinned
            ] as [String : Any]
            
            strongSelf.database.child("announcement_grades").observeSingleEvent(of: .value, with: { snapshot in
                if var announcementGrades = snapshot.value as? [[String: Any]] {
                    for index in 0...announcementGrades.count - 1 {
                        guard let checkGrade = announcementGrades[index]["grade"] as? Int else {
                            completion(false)
                            return
                        }
                        
                        if checkGrade == newAnnouncement.grade {
                            guard var announcements = announcementGrades[index]["announcements"] as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            announcements.append(newAnnouncementEntry)
                            announcementGrades[index].updateValue(announcements, forKey: "announcements")
                            
                            let newLatestAnnouncementEntry = [
                                "sent_date": newAnnouncement.sentDate,
                                "title": newAnnouncement.title,
                                "sender_name": newAnnouncement.senderName,
                                "sender_email": newAnnouncement.senderEmail
                            ]
                            announcementGrades[index].updateValue(newLatestAnnouncementEntry, forKey: "latest_announcement")
                        }
                    }
                    strongSelf.database.child("announcement_grades").setValue(announcementGrades, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                else {
                    completion(false)
                }
            })
        })
    }
    
    public func getAllAnnouncementGrades(completion: @escaping (Result<[AnnouncementGrade], Error>) -> Void) {
        verifySession(completion: { [weak self] success in
            guard success, let strongSelf = self else {
                completion(.failure(DatabaseError.failedToVerify))
                return
            }
            strongSelf.database.child("announcement_grades").observe(.value, with: { snapshot in
                guard let value = snapshot.value as? [[String: Any]] else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                let announcementGrades: [AnnouncementGrade] = value.compactMap({ dictionary in
                    guard let grade = dictionary["grade"] as? Int, let latestAnnouncement = dictionary["latest_announcement"] as? [String: Any], let date = latestAnnouncement["sent_date"] as? String, let title = latestAnnouncement["title"] as? String, let sender = latestAnnouncement["sender_name"] as? String, let senderEmail = latestAnnouncement["sender_email"] as? String else {
                        return nil
                    }
                    
                    let latestAnnouncementObject = LatestAnnouncement(sentDate: date, title: title, senderName: sender, senderEmail: senderEmail)
                    return AnnouncementGrade(grade: grade, latestAnnouncement: latestAnnouncementObject)
                })
                completion(.success(announcementGrades))
            })
        })
    }
    public func getAllAnnouncements(for grade: Int, completion: @escaping (Result<[Announcement], Error>) -> Void) {
        verifySession(completion: { [weak self] success in
            guard success, let strongSelf = self else {
                completion(.failure(DatabaseError.failedToVerify))
                return
            }
            strongSelf.database.child("announcement_grades").observe(.value, with: { snapshot in
                guard let announcementGrades = snapshot.value as? [[String: Any]] else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                var announcementsList: [[String: Any]] = []
                for index in 0...announcementGrades.count - 1 {
                    guard let checkGrade = announcementGrades[index]["grade"] as? Int else {
                        completion(.failure(DatabaseError.failedToFetch))
                        return
                    }
                    
                    if checkGrade == grade {
                        guard let announcementsCollection = announcementGrades[index]["announcements"] as? [[String: Any]] else {
                            completion(.failure(DatabaseError.failedToFetch))
                            return
                        }
                        announcementsList = announcementsCollection
                    }
                }
                
                var announcements: [Announcement] = announcementsList.compactMap({ dictionary in
                    guard let announcementTitle = dictionary["title"] as? String, let announcementBody = dictionary["body"] as? String, let announcementAttachments = dictionary["attachments"] as? URL?, let announcementGrade = dictionary["grade"] as? Int, let announcementDate = dictionary["sent_date"] as? String, let announcementEmail = dictionary["sender_email"] as? String, let announcementName = dictionary["sender_name"] as? String, let announcementId = dictionary["announcement_id"] as? String, let pinned = dictionary["pinned"] as? Bool else {
                        return nil
                    }
                    
                    return Announcement(title: announcementTitle, body: announcementBody, attachments: announcementAttachments, grade: announcementGrade, sentDate: announcementDate, senderEmail: announcementEmail, senderName: announcementName, announcementId: announcementId, pinned: pinned)
                })
                
                completion(.success(announcements))
            })
        })
    }
    public func changeAnnouncementPinned(to pinned: Bool, announcementId: String, grade: Int, completion: @escaping (Bool) -> Void) {
        verifyDean(completion: { [weak self] success in
            guard success, let strongSelf = self else {
                completion(false)
                return
            }
            strongSelf.database.child("announcement_grades").observeSingleEvent(of: .value, with: { snapshot in
                guard let announcementGrades = snapshot.value as? [[String: Any]] else {
                    completion(false)
                    return
                }
                
                var newAnnouncementGrades: [[String: Any]] = []
                for announcementGrade in announcementGrades {
                    guard let checkGrade = announcementGrade["grade"] as? Int else {
                        completion(false)
                        return
                    }
                    
                    var newAnnouncementGrade = announcementGrade
                    
                    if checkGrade == grade {
                        guard let announcements = announcementGrade["announcements"] as? [[String: Any]] else {
                            completion(false)
                            return
                        }
                        
                        var newAnnouncements: [[String: Any]] = []
                        
                        for announcement in announcements {
                            guard let checkAnnouncementId = announcement["announcement_id"] as? String else {
                                completion(false)
                                return
                            }
                            
                            var newAnnouncement = announcement
                            if checkAnnouncementId == announcementId {
                                newAnnouncement.updateValue(pinned, forKey: "pinned")
                            }
                            newAnnouncements.append(newAnnouncement)
                        }
                        newAnnouncementGrade.updateValue(newAnnouncements, forKey: "announcements")
                    }
                    newAnnouncementGrades.append(newAnnouncementGrade)
                }
                strongSelf.database.child("announcement_grades").setValue(newAnnouncementGrades, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        print(error as Any)
                        completion(false)
                        return
                    }
                    completion(true)
                })
            })
        })
    }
}

//// MARK: - Sending notifications
//
//extension DatabaseManager {
//    public func sendDeviceTokenToServer(data: Data) {
//        let stringData = String(decoding: data, as: UTF8.self)
//        guard !stringData.isEmpty else {
//            print("Failed to upload info to database, datastring")
//            return
//        }
//        self.database.child("notification_info").observeSingleEvent(of: .value, with: { [weak self] snapshot in
//            guard let strongSelf = self else {
//                print("Failed to upload info to database, self")
//                return
//            }
//            if var infoCollection = snapshot.value as? [String] {
//                //append to info array
//                infoCollection.append(stringData)
//                strongSelf.database.child("notification_info").setValue(infoCollection, withCompletionBlock: { error, _ in
//                    guard error == nil else {
//                        print("Failed to upload info to database, setValue")
//                        print(error as Any)
//                        return
//                    }
//                })
//            }
//            else {
//                //create that array
//                let newCollection: [String] = [stringData]
//
//                strongSelf.database.child("notification_info").setValue(newCollection, withCompletionBlock: { error, _ in
//                    guard error == nil else {
//                        print("Failed to upload info to database, setValue2")
//                        print(error as Any)
//                        return
//                    }
//                })
//            }
//        })
//    }
//
//    func sendNotification(apnsToken: String, title: String, body: String) {
//
//        let params = [
//            "aps" : [
//                "alert" : [
//                    "title" : title,
//                    "body" : body
//                ]
//            ]
//        ]
//
//        let headers = [
//            ":method": "POST",
//            ":scheme": "http",
//            ":path": "/3/device/\(apnsToken)",
//            "apns-push-type": "alert"
//        ]
//
//        request("https://api.push.apple.com", method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).response { response in
//            debugPrint(response)
//        }
//    }
//}

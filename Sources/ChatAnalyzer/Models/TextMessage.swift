//
//  TextMessage.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation

public struct TextMessage: ChatMessage {
    public let user: String
    public let timestamp: Date
    public let messageType: MessageType
    public let message: String
    public var sentimentLabel: String?
    
    public init(user: String, timestamp: Date, messageType: MessageType, message: String, sentimentLabel: String?) {
        self.user = user
        self.timestamp = timestamp
        self.messageType = messageType
        self.message = message
        self.sentimentLabel = sentimentLabel
    }
}

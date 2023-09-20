//
//  WhatsAppPollMessage.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation

struct WhatsAppPollMessage: ChatMessage {
    let user: String
    let timestamp: Date
    let messageType: MessageType
    let question: String
    let options: [WhatsAppPollOption]
    
    enum CodingKeys: String, CodingKey {
        case user
        case timestamp
        case messageType = "message_type"
        case question
        case options
    }
    
    init(user: String, timestamp: Date, messageType: MessageType, question: String, options: [WhatsAppPollOption]) {
        self.user = user
        self.timestamp = timestamp
        self.messageType = messageType
        self.question = question
        self.options = options
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(String.self, forKey: .user)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        messageType = try container.decode(MessageType.self, forKey: .messageType)
        question = try container.decode(String.self, forKey: .question)
        options = try container.decode([WhatsAppPollOption].self, forKey: .options)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(messageType, forKey: .messageType)
        try container.encode(question, forKey: .question)
        try container.encode(options, forKey: .options)
    }
}

struct WhatsAppPollOption: Equatable, Hashable, Codable {
    let option: String
    let count: Int
}

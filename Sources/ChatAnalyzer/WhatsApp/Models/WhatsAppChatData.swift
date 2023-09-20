//
//  WhatsAppChatData.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation

public struct WhatsAppChatData: ChatData {
    public var messages: [any ChatMessage]
    public let metadata: WhatsAppMetadata
    public var isSentimentAnalyzed: Bool
    
    enum CodingKeys: CodingKey {
        case messages
        case metadata
        case isSentimentAnalyzed
    }

    public init(messages: [any ChatMessage], metadata: WhatsAppMetadata) {
        self.messages = messages
        self.metadata = metadata
        self.isSentimentAnalyzed = false
    }
}

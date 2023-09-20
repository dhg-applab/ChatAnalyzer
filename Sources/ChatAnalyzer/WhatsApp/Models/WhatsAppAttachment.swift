//
//  WhatsAppAttachment.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation

struct WhatsAppAttachment: ChatMessage {
    let user: String
    let timestamp: Date
    let messageType: MessageType
    let attachment: String
    let attachmentExtension: String
}

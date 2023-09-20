//
//  WhatsAppLocationMessage.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation

struct WhatsAppLocationMessage: ChatMessage {
    let user: String
    let timestamp: Date
    let messageType: MessageType
    let location: String
    let city: String
    let latitude: String
    let longitude: String
}

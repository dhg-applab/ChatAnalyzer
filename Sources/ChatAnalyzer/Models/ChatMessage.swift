//
//  ChatMessage.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation

public protocol ChatMessage: Codable, Hashable {
    var user: String { get }
    var timestamp: Date { get }
    var messageType: MessageType { get }
}

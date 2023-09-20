//
//  ChatData.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation

public protocol ChatData {
    associatedtype ChatMetadataType: ChatMetadata
    
    var messages: [any ChatMessage] { get set }
    var metadata: ChatMetadataType { get }
    var isSentimentAnalyzed: Bool { get set }
    
    init(messages: [any ChatMessage], metadata: ChatMetadataType)
}

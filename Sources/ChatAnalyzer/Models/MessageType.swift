//
//  MessageType.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

public enum MessageType: Codable {
    case text
    case sticker
    case voiceMessage
    case photo
    case video
    case viewOncePhoto
    case viewOnceVideo
    case file
    case location
    case contact
    case poll
}

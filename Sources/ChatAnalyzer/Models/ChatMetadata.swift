//
//  ChatMetadata.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation

public protocol ChatMetadata: Codable {
    var numberOfUsers: Int { get set }
    var numberOfMessages: Int { get set }
    var numberOfTexts: Int { get set }
    var numberOfPhotos: Int { get set }
    var numberOfVideos: Int { get set }
    var numberOfVoiceMessages: Int { get set }
    var numberOfStickers: Int { get set }
    var numberOfEmojis: Int { get set }
    var numberOfFiles: Int { get set }
}

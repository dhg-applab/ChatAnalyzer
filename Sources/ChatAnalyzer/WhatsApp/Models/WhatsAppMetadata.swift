//
//  WhatsAppMetadata.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation

public struct WhatsAppMetadata: ChatMetadata {
    public var numberOfUsers: Int
    public var numberOfMessages: Int
    public var numberOfTexts: Int
    public var numberOfPhotos: Int
    public var numberOfVideos: Int
    public var numberOfVoiceMessages: Int
    public var numberOfStickers: Int
    public var numberOfEmojis: Int
    public var numberOfFiles: Int
    public var numberOfViewOncePhotos: Int
    public var numberOfViewOnceVideos: Int
    public var numberOfLocations: Int
    public var numberOfContacts: Int
    public var numberOfPolls: Int

    public init(
        numberOfUsers: Int = 0,
        numberOfMessages: Int = 0,
        numberOfTexts: Int = 0,
        numberOfPhotos: Int = 0,
        numberOfVideos: Int = 0,
        numberOfVoiceMessages: Int = 0,
        numberOfStickers: Int = 0,
        numberOfEmojis: Int = 0,
        numberOfFiles: Int = 0,
        numberOfViewOncePhotos: Int = 0,
        numberOfViewOnceVideos: Int = 0,
        numberOfLocations: Int = 0,
        numberOfContacts: Int = 0,
        numberOfPolls: Int = 0) {
            self.numberOfUsers = numberOfUsers
            self.numberOfMessages = numberOfMessages
            self.numberOfTexts = numberOfTexts
            self.numberOfPhotos = numberOfPhotos
            self.numberOfVideos = numberOfVideos
            self.numberOfVoiceMessages = numberOfVoiceMessages
            self.numberOfStickers = numberOfStickers
            self.numberOfEmojis = numberOfEmojis
            self.numberOfFiles = numberOfFiles
            self.numberOfViewOncePhotos = numberOfViewOncePhotos
            self.numberOfViewOnceVideos = numberOfViewOnceVideos
            self.numberOfLocations = numberOfLocations
            self.numberOfContacts = numberOfContacts
            self.numberOfPolls = numberOfPolls
        }
}

//
//  ZipHelper.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation
import ZIPFoundation
import os.log

class ZipHelper {
    func unzipWhatsApp(at sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager()
        
        do {
            try fileManager.unzipItem(at: sourceURL, to: destinationURL)
            
            // Find chat file in the unzipped directory
            guard let chatFileURL = try ZipHelper.findChatFile(in: destinationURL, chatFileName: WhatsAppConstants.chatFileName, fileManager: fileManager) else {
                os_log("Failed to find chat file.", type: .error)
                throw ZipHelperError.chatFileNotFound
            }
            
            // Move files to unzippedURL if necessary
            if chatFileURL.deletingLastPathComponent().path != destinationURL.path {
                let subdirectoryURL = chatFileURL.deletingLastPathComponent()
                let subdirectoryContents = try fileManager.contentsOfDirectory(at: subdirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                for contentURL in subdirectoryContents {
                    let newLocationURL = destinationURL.appendingPathComponent(contentURL.lastPathComponent)
                    try fileManager.moveItem(at: contentURL, to: newLocationURL)
                }
                try fileManager.removeItem(at: subdirectoryURL)
            }
        } catch {
            os_log("Failed to unzip WhatsApp chat file: %@", type: .error, error.localizedDescription)
            throw error
        }
    }

    static func findChatFile(in directoryURL: URL, chatFileName: String, fileManager: FileManager) throws -> URL? {
        let directoryContents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        for contentURL in directoryContents {
            if contentURL.lastPathComponent == chatFileName {
                return contentURL
            } else if contentURL.hasDirectoryPath, let chatFileURL = try findChatFile(in: contentURL, chatFileName: chatFileName ,fileManager: fileManager) {
                return chatFileURL
            }
        }
        return nil
    }
}

enum ZipHelperError: Error {
    case chatFileNotFound
}

extension ZipHelperError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .chatFileNotFound:
            return NSLocalizedString("The chat file can not be found the in zip file.", comment: "Chat File Not Found")
        }
    }
}

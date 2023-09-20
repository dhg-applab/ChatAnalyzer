//
//  SentimentModel.swift
//  
//
//  Created by Junpeng Chen on 27.07.23.
//

import Foundation

protocol SentimentModel {
    func analyzeSentiment(for text: String) -> String?
    func analyzeSentiment(for texts: [String]) -> [String]
}

enum SentimentModelError: Error {
    case modelNotFound
}

extension SentimentModelError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return NSLocalizedString("The model is not found.", comment: "Model Not Found")
        }
    }
}

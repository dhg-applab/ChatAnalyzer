//
//  SentimentModel.swift
//  
//
//  Created by Junpeng Chen on 27.07.23.
//

import Foundation

protocol SentimentModel {
    func analyzeSentiment(for text: String) throws -> String
    func analyzeSentiment(for texts: [String]) throws -> [String]
}

enum SentimentModelError: Error {
    case modelNotFound
    case predictionFailed
}

extension SentimentModelError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return NSLocalizedString("The model is not found.", comment: "Model Not Found")
        case .predictionFailed:
            return NSLocalizedString("Failed to predict a label.", comment: "Prediction Failed")
        }
    }
}

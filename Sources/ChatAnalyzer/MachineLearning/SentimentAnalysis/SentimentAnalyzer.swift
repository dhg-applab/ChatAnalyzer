//
//  SentimentAnalyzer.swift
//  
//
//  Created by Junpeng Chen on 27.07.23.
//

import CoreML
import Foundation
import NaturalLanguage

class SentimentAnalyzer {
    private let sentimentModel: SentimentModel

    init(modelType: SentimentModelType) throws {
        switch modelType {
        case .BERTSST2:
            sentimentModel = try CreateMLModel(modelType: .BERTSST2)
        case .BiLSTM:
            sentimentModel = try DNNModel(modelType: .BiLSTM)
            throw SentimentAnalyzerError.modelNotFound
        }
    }
    
    func analyzeSentiment(for message: any ChatMessage) -> String {
        let textMessage = message as! TextMessage
        if let sentimentLabel = sentimentModel.analyzeSentiment(for: textMessage.message) {
            return sentimentLabel
        } else {
            return "None"
        }
    }
    
    func analyzeSentiment(for texts: [String]) -> [String] {
        return sentimentModel.analyzeSentiment(for: texts)
    }
    
    func analyzeSentiment(for textMessages: [TextMessage]) -> [String] {
        let messages = textMessages.map { $0.message }
        let predictions = sentimentModel.analyzeSentiment(for: messages)
        return predictions
    }

    func analyzeSentiment(for chatData: some ChatData) -> [String] {
        let textMessages = chatData.messages
            .filter { $0.messageType == MessageType.text }
            .map { $0 as! TextMessage }
        let predictions = analyzeSentiment(for: textMessages)
        return predictions
    }
}

enum SentimentAnalyzerError: Error {
    case modelNotFound
    case predictionFailed
}

extension SentimentAnalyzerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return NSLocalizedString("The model is not found.", comment: "Model Not Found")
        case .predictionFailed:
            return NSLocalizedString("The prediction failed.", comment: "Prediction Failed")
        }
    }
}

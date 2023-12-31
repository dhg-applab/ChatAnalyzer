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
    
    func analyzeSentiment(for message: any ChatMessage) throws -> String {
        let textMessage = message as! TextMessage
        do {
            return try sentimentModel.analyzeSentiment(for: textMessage.message)
        } catch {
            throw SentimentAnalyzerError.predictionFailed
        }
    }
    
    func analyzeSentiment(for texts: [String]) throws -> [String] {
        do {
            return try sentimentModel.analyzeSentiment(for: texts)
        } catch {
            throw SentimentAnalyzerError.predictionFailed
        }
    }
    
    func analyzeSentiment(for textMessages: [TextMessage]) throws -> [String] {
        let messages = textMessages.map { $0.message }
        do {
            let predictions = try sentimentModel.analyzeSentiment(for: messages)
            return predictions
        } catch {
            throw SentimentAnalyzerError.predictionFailed
        }
    }

    func analyzeSentiment(for chatData: some ChatData) throws -> [String] {
        let textMessages = chatData.messages
            .filter { $0.messageType == MessageType.text }
            .map { $0 as! TextMessage }
        do {
            let predictions = try analyzeSentiment(for: textMessages)
            return predictions
        } catch {
            throw SentimentAnalyzerError.predictionFailed
        }
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
            return NSLocalizedString("Failed to predict sentiment.", comment: "Sentiment Analysis Failed")
        }
    }
}

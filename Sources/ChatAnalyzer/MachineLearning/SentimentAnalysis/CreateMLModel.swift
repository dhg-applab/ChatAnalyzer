//
//  CreateMLModel.swift
//  
//
//  Created by Junpeng Chen on 27.07.23.
//

import CoreML
import Foundation
import NaturalLanguage

class CreateMLModel: SentimentModel {
    private let sentimentPredictor: NLModel

    init(modelType: SentimentModelType) throws {
        let mlModel: MLModel
        
        switch modelType {
        case .BERTSST2:
            mlModel = try BERTSST2(configuration: MLModelConfiguration()).model
        default:
            throw SentimentModelError.modelNotFound
        }
        
        sentimentPredictor = try NLModel(mlModel: mlModel)
    }
    
    func analyzeSentiment(for text: String) throws -> String {
        let predictedLabel = sentimentPredictor.predictedLabel(for: text)
        switch predictedLabel {
        case "positive":
            return "Positive"
        case "negative":
            return "Negative"
        default:
            throw SentimentModelError.predictionFailed
        }
    }
    
    func analyzeSentiment(for texts: [String]) throws -> [String] {
        let predictedLabels = try texts.map { try self.analyzeSentiment(for: $0) }
        return predictedLabels
    }
}

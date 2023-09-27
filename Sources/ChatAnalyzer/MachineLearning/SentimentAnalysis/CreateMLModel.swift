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
    
    func analyzeSentiment(for text: String) -> String? {
        guard let predictedLabel = sentimentPredictor.predictedLabel(for: text) else {
            return nil
        }
        switch predictedLabel {
        case "positive":
            return "Positive"
        case "negative":
            return "Negative"
        default:
            return nil
        }
    }
    
    func analyzeSentiment(for texts: [String]) -> [String] {
        var predictedLabels = [String]()
        for text in texts {
            if let predictedLabel = self.analyzeSentiment(for: text) {
                predictedLabels.append(predictedLabel)
            } else {
                predictedLabels.append("None")
            }
        }
        return predictedLabels
    }
}

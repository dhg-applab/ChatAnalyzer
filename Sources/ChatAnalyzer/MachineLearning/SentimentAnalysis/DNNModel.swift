//
//  DNNModel.swift
//  
//
//  Created by Junpeng Chen on 27.07.23.
//

import CoreML
import Foundation

class DNNModel: SentimentModel {
    private let mlModel: MLModel
    private let tokenizer: Tokenizer
    private let sequenceLength: Int
    private let modelType: SentimentModelType

    init(modelType: SentimentModelType) throws {
        self.modelType = modelType
        switch modelType {
        case .BiLSTM:
            guard let vocabURL = Bundle.main.url(forResource: "BiLSTM_vocab.txt", withExtension: nil) else {
                fatalError("Failed to find vocabulary file for BiLSTM.")
            }
            sequenceLength = 128
            tokenizer = Tokenizer(maxTokens: 20000, sequenceLength: sequenceLength, vocabularyURL: vocabURL)
            mlModel = try BiLSTM(configuration: MLModelConfiguration()).model

        default:
            throw SentimentModelError.modelNotFound
        }
    }
    
    private func getPrediction(input: MLMultiArray) -> (label: String, probabilities: [String: Double])? {
        let input = BiLSTMInput(input: input)

        guard let output = try? mlModel.prediction(from: input) else {
            return nil
        }

        guard let prediction = output.featureValue(for: "Identity")?.multiArrayValue?[0].doubleValue else {
            return nil
        }

        let predictedLabel = prediction > 0.5 ? "Positive" : "Negative"

        let probabilities = [
            "Positive": prediction,
            "Negative": 1 - prediction
        ]

        return (label: predictedLabel, probabilities: probabilities)
    }

    func analyzeSentiment(for message: String) throws -> String {
        let inputTokens = tokenizer.tokenize(message)

        let inputMultiArray = try MLMultiArray(shape: [1, sequenceLength] as [NSNumber], dataType: .int32)

        for (index, tokenId) in inputTokens.enumerated() {
            inputMultiArray[index] = NSNumber(value: tokenId)
        }

        guard let prediction = getPrediction(input: inputMultiArray) else {
            throw SentimentModelError.predictionFailed
        }

        return prediction.label
    }

    func analyzeSentiment(for texts: [String]) throws -> [String] {
        let predictedLabels = try texts.map { try self.analyzeSentiment(for: $0) }
        return predictedLabels
    }
}

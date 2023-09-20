//
//  Tokenizer.swift
//  
//
//  Created by Junpeng Chen on 27.07.23.
//

import Foundation

class Tokenizer {
    let paddingToken = "[PAD]"
    let unknownToken = "[UNK]"
    
    let maxTokens: Int
    let sequenceLength: Int
    
    var vocabulary: [String:Int]?
    
    init(maxTokens: Int, sequenceLength: Int) {
        self.maxTokens = maxTokens
        self.sequenceLength = sequenceLength
    }
    
    init(maxTokens: Int, sequenceLength: Int, vocabularyURL: URL) {
        self.maxTokens = maxTokens
        self.sequenceLength = sequenceLength
        setVocabulary(fromURL: vocabularyURL)
    }
    
    func cleanText(_ text: String) -> String {
        let cleanedText = text
            .replacingOccurrences(of: "[^A-Za-z0-9(),!?'`]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression) // Replace multiple consecutive whitespace characters with a single whitespace
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return cleanedText
    }
    
    func tokenize(_ text: String) -> [Int] {
        guard let vocab = vocabulary else {
            fatalError("Vocabulary has not been set")
        }
        
        let cleanedText = cleanText(text)
        let tokens = cleanedText.split(separator: " ").map(String.init)
        var tokenIds: [Int] = []
        for token in tokens {
            if tokenIds.count >= sequenceLength {
                break
            }
            
            if let tokenId = vocab[token] {
                tokenIds.append(tokenId)
            } else {
                tokenIds.append(vocab[unknownToken]!)
            }
        }
        
        while tokenIds.count < sequenceLength {
            tokenIds.append(vocab[paddingToken]!)
        }
        
        return tokenIds
    }
    
    func buildVocabulary(data: [String]) {
        var vocab = [paddingToken: 0, unknownToken: 1]
        var currentId = 2
        var tokenFrequencies = [String: Int]()
        
        for text in data {
            let cleanedText = cleanText(text)
            let tokens = cleanedText.split(separator: " ").map(String.init)
            
            for token in tokens {
                tokenFrequencies[token, default: 0] += 1
            }
        }
        
        // Sort tokens by frequency in descending order
        let sortedTokens = tokenFrequencies.sorted { $0.value > $1.value }
        
        // Assign IDs to tokens based on frequency
        for (token, _) in sortedTokens {
            if currentId >= maxTokens {
                break
            }
            vocab[token] = currentId
            currentId += 1
        }
        
        self.vocabulary = vocab
    }
    
    func setVocabulary(fromURL url: URL) {
        do {
            let fileContent = try String(contentsOf: url)
            let tokens = fileContent.split(separator: "\n").map(String.init)
            
            var vocab = [String: Int](minimumCapacity: tokens.count)
            var currentId = 0
            
            for token in tokens {
                vocab[token] = currentId
                currentId += 1
            }
            
            self.vocabulary = vocab
        } catch {
            fatalError("Failed to read vocabulary file: \(error)")
        }
    }
}

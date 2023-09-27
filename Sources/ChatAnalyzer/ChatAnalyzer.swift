//
//  ChatAnalyzer.swift
//  
//
//  Created by Junpeng Chen on 26.07.23.
//

import Foundation
import NaturalLanguage
import os.log

public protocol ChatAnalyzer {
    associatedtype ChatDataType: ChatData
    
    static func extractChatData(from fileURL: URL) throws -> ChatDataType
    func getChatData() -> ChatDataType
    func getLanguage() -> NLLanguage
    func setLanguage(language: NLLanguage)
    func uniqueUsers() -> Set<String>
    func userCount() -> Int
    func uniqueDays(user: String?, messageType: MessageType?, startTime: Date?, endTime: Date?) throws -> Set<String>
    func uniqueDaysByUser(messageType: MessageType?, startTime: Date?, endTime: Date?) throws -> Dictionary<String, Set<String>>
    func dayCount(user: String?, messageType: MessageType?, startTime: Date?, endTime: Date?) throws -> Int
    func dayCountByUser(messageType: MessageType?, startTime: Date?, endTime: Date?) throws -> Dictionary<String, Int>
    func messageCount(user: String?, messageType: MessageType?, startTime: Date?, endTime: Date?) throws -> Int
    func messageCountByUser(messageType: MessageType?, startTime: Date?, endTime: Date?) throws -> Dictionary<String, Int>
    func messageCountByFrequency(frequency: Frequency, user: String?, messageType: MessageType?, startTime: Date?, endTime: Date?) throws -> Dictionary<DateComponents, Int>
    func messageCountByFrequencyByUser(frequency: Frequency, messageType: MessageType?, startTime: Date?, endTime: Date?) throws -> Dictionary<String, Dictionary<DateComponents, Int>>
    func messageCountByFrequency(frequencies: [Frequency], user: String?, messageType: MessageType?, startTime: Date?, endTime: Date?) throws -> Dictionary<Frequency, [(date: DateComponents, count: Int)]>
    func messageCountByFrequencyByUser(frequencies: [Frequency], messageType: MessageType?, startTime: Date?, endTime: Date?) throws -> Dictionary<String, Dictionary<Frequency, [(date: DateComponents, count: Int)]>>
    func wordCount(removeStopWords: Bool, user: String?, startTime: Date?, endTime: Date?) throws -> Int
    func wordCountByUser(removeStopWords: Bool, startTime: Date?, endTime: Date?) throws -> Dictionary<String, Int>
    func uniqueWordCount(removeStopWords: Bool, user: String?, startTime: Date?, endTime: Date?) throws -> Int
    func uniqueWordCountByUser(removeStopWords: Bool, startTime: Date?, endTime: Date?) throws -> Dictionary<String, Int>
    func mostCommonWords(n: Int, removeStopWords: Bool, user: String?, startTime: Date?, endTime: Date?) throws -> [(word: String, count: Int)]
    func mostCommonWordsByUser(n: Int, removeStopWords: Bool, startTime: Date?, endTime: Date?) throws -> [(user: String, mostCommonWords: [(word: String, count: Int)])]
    func emojiCount(user: String?, startTime: Date?, endTime: Date?) throws -> Int
    func emojiCountByUser(startTime: Date?, endTime: Date?) throws -> Dictionary<String, Int>
    func uniqueEmojiCount(user: String?, startTime: Date?, endTime: Date?) throws -> Int
    func uniqueEmojiCountByUser(startTime: Date?, endTime: Date?) throws -> Dictionary<String, Int>
    func mostCommonEmojis(n: Int, user: String?, startTime: Date?, endTime: Date?) throws -> [(emoji: Character, count: Int)]
    func mostCommonEmojisByUser(n: Int, startTime: Date?, endTime: Date?) throws -> Dictionary<String, [(emoji: Character, count: Int)]>
    func metadata(user: String?, startTime: Date?, endTime: Date?) throws -> ChatDataType.ChatMetadataType
    func metadataByUser(startTime: Date?, endTime: Date?) throws -> Dictionary<String, ChatDataType.ChatMetadataType>
    func analyzeSentiment() throws -> [any ChatMessage]
    func analyzeSentimentByFrequency(frequency: Frequency, user: String?, startTime: Date?, endTime: Date?) throws -> [(date: DateComponents, sentimentCounts: [(sentiment: String, count: Int)])]
    func analyzeSentimentByFrequency(frequencies: [Frequency], user: String?, startTime: Date?, endTime: Date?) throws -> Dictionary<Frequency, [(date: DateComponents, sentimentCounts: [(sentiment: String, count: Int)])]>
    func longestMessage(user: String?, startTime: Date?, endTime: Date?) throws -> Int
    func longestMessageByUser(startTime: Date?, endTime: Date?) throws -> [String: Int]
    func chatDuration(user: String?) throws -> DateInterval
    func chatDurationByUser() throws -> [String: DateInterval]
    func averageMessageLength(user: String?, startTime: Date?, endTime: Date?) throws -> Double
    func averageMessageLengthByUser(startTime: Date?, endTime: Date?) throws -> [String: Double]
    func averageReplyTime(user: String, startTime: Date?, endTime: Date?) throws -> TimeInterval
    func averageReplyTimeByUser(startTime: Date?, endTime: Date?) throws -> [String: TimeInterval]
}

extension ChatAnalyzer {
    static func identifyLanguage(chatData: ChatDataType, sampleRatio: Double = 0.1, minSampleSize: Int = 100) throws -> NLLanguage {
        // Sample the text messages
        let textMessages = chatData.messages.filter { $0.messageType == .text }.map { ($0 as! TextMessage).message }
        let messageCount = textMessages.count
        let sampleSize = min(messageCount, max(Int((Double(messageCount) * sampleRatio).rounded()), minSampleSize))
        let sampledMessages = textMessages.shuffled().prefix(sampleSize)
        let sampledMessagesJoined = sampledMessages.joined()
        
        // Identify the dominant language in the messages
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(sampledMessagesJoined)
        if let language = recognizer.dominantLanguage {
            return language
        } else {
            throw ChatAnalyzerError.languageNotRecognized
        }
    }
    
    static func getStopWords(language: NLLanguage) throws -> [String] {
        let filename: String
        switch language {
        case .english:
            filename = "stop_words_en"
        case .german:
            filename = "stop_words_de"
        default:
            throw ChatAnalyzerError.languageNotSupported
        }
        if let fileURL = Bundle.module.url(forResource: filename, withExtension: "txt") {
            do {
                let contents = try String(contentsOf: fileURL)
                return contents.components(separatedBy: .newlines)
            } catch {
                os_log("Failed to load stop words: %@", type: .error, error.localizedDescription)
                throw ChatAnalyzerError.loadStopWordsFailed
            }
        } else {
            os_log("Stop words file is not found", type: .error)
            throw ChatAnalyzerError.loadStopWordsFailed
        }
    }
    
    static func tokenize(messages: [String], language: NLLanguage, removeStopWords: Bool = false) throws -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        
        let messagesJoined = messages.joined(separator: " ")
        tokenizer.string = messagesJoined
        
        var words = [String]()
        if removeStopWords {
            let stopWords = try Self.getStopWords(language: language)
            tokenizer.enumerateTokens(in: messagesJoined.startIndex..<messagesJoined.endIndex) { tokenRange, _ in
                let word = String(messagesJoined[tokenRange])
                if !stopWords.contains(word) {
                    words.append(word)
                }
                return true
            }
        } else {
            tokenizer.enumerateTokens(in: messagesJoined.startIndex..<messagesJoined.endIndex) { tokenRange, _ in
                words.append(String(messagesJoined[tokenRange]))
                return true
            }
        }
        return words
    }
    
    static func calculateSentimentCount(messages: [TextMessage], frequency: Frequency, calendar: Calendar) throws -> [(date: DateComponents, sentimentCounts: [(sentiment: String, count: Int)])] {
        // Count the sentiment labels for each date
        var sentimentCountByFrequency = [DateComponents: [String: Int]]()
        for message in messages {
            let date: DateComponents
            switch frequency {
            case .year:
                date = calendar.dateComponents([.calendar, .year], from: message.timestamp)
            case .month:
                date = calendar.dateComponents([.calendar, .year, .month], from: message.timestamp)
            case .week:
                date = calendar.dateComponents([.calendar, .year, .weekOfYear], from: message.timestamp)
            case .day:
                date = calendar.dateComponents([.calendar, .year, .month, .day], from: message.timestamp)
            case .weekday:
                date = calendar.dateComponents([.calendar, .weekday], from: message.timestamp)
            case .hour:
                date = calendar.dateComponents([.calendar, .hour], from: message.timestamp)
            }
            guard let sentimentLabel = message.sentimentLabel else {
                throw ChatAnalyzerError.sentimentNotAnalyzed
            }
            sentimentCountByFrequency[date, default: [String: Int]()][sentimentLabel, default: 0] += 1
        }
        
        // Construct array of sentiment frequencies
        var sentimentFrequencies = [(date: DateComponents, sentimentCounts: [(sentiment: String, count: Int)])]()
        sentimentCountByFrequency
            .sorted { $0.key < $1.key }
            .forEach { date, frequencies in
                let sentimentCounts = frequencies
                    .map { sentiment, count in
                        (sentiment: sentiment, count: count)
                    }
                    .sorted { $0.sentiment < $1.sentiment }
                sentimentFrequencies.append((date: date, sentimentCounts: sentimentCounts))
            }
        
        return sentimentFrequencies
    }
    
    static func calculateChatDuration(messages: [TextMessage]) throws -> DateInterval {
        let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
        if let firstMessage = sortedMessages.first,
           let lastMessage = sortedMessages.last {
            return DateInterval(start: firstMessage.timestamp, end: lastMessage.timestamp)
        } else {
            throw ChatAnalyzerError.noTextMessage
        }
    }
    
    static func calculateAverageMessageLength(messages: [String]) throws -> Double {
        if messages.count == 0 {
            return 0
        }
        let totalLength = messages.reduce(0, { $0 + $1.count })
        let averageLength = Double(totalLength) / Double(messages.count)
        return averageLength
    }
    
    static func calculateAverageReplyTime(messages: [TextMessage], user: String) throws -> TimeInterval {
        var replyTime = 0.0
        var numReplies = 0
        var lastMessageTime: Date? = nil
        var replied = false
        
        let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
        for message in sortedMessages {
            if message.user == user {
                if !replied, let lastMessageTime = lastMessageTime {
                    replyTime += abs(message.timestamp.distance(to: lastMessageTime))
                    numReplies += 1
                    replied = true
                }
            } else {
                lastMessageTime = message.timestamp
                replied = false
            }
        }
        
        if numReplies == 0 {
            throw ChatAnalyzerError.noTextMessage
        }
        
        return replyTime / Double(numReplies)
    }
}

public enum ChatAnalyzerError: Error {
    case chatFileNoAccess
    case createDirectoryFailed
    case extractDataFailed
    case invalidChatFile
    case unzipFailed
    case languageNotRecognized
    case userNotFound
    case languageNotSupported
    case loadStopWordsFailed
    case sentimentAnalysisFailed
    case sentimentNotAnalyzed
    case noTextMessage
}

extension ChatAnalyzerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .chatFileNoAccess:
            return NSLocalizedString("No permission to access the chat file.", comment: "No Access To Chat File")
        case .createDirectoryFailed:
            return NSLocalizedString("Failed to create directory.", comment: "Create Directory Failed")
        case .extractDataFailed:
            return NSLocalizedString("Failed to extract chat data.", comment: "Extract Chat Data Failed")
        case .invalidChatFile:
            return NSLocalizedString("The chat file is invalid.", comment: "Invalid Chat File")
        case .unzipFailed:
            return NSLocalizedString("Failed to unzip the file.", comment: "Unzip Failed")
        case .languageNotRecognized:
            return NSLocalizedString("Failed to identify the language in the chat.", comment: "Language Identification Failed")
        case .userNotFound:
            return NSLocalizedString("The user does not exist in the chat.", comment: "User Not Found")
        case .languageNotSupported:
            return NSLocalizedString("The language is not supported.", comment: "Language Not Supported")
        case .loadStopWordsFailed:
            return NSLocalizedString("Failed to load stop words.", comment: "Load Stop Words Failed")
        case .sentimentAnalysisFailed:
            return NSLocalizedString("Failed to perform sentiment analysis.", comment: "Sentiment Analysis Failed")
        case .sentimentNotAnalyzed:
            return NSLocalizedString("The sentiments aren't analyzed.", comment: "Sentiment Not Analyzed")
        case .noTextMessage:
            return NSLocalizedString("No text message in the chat.", comment: "No Text Message")
        }
    }
}

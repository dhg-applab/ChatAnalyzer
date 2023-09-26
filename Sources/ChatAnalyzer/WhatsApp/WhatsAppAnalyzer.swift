//
//  WhatsAppAnalyzer.swift
//  
//
//  Created by Junpeng Chen on 27.07.23.
//

import Foundation
import NaturalLanguage
import UniformTypeIdentifiers
import os.log

public class WhatsAppAnalyzer: ChatAnalyzer {
    
    private var chatData: WhatsAppChatData
    private var language: NLLanguage
    
    public init(fileURL: URL) throws {
        self.chatData = try WhatsAppAnalyzer.extractChatData(from: fileURL)
        self.language = try WhatsAppAnalyzer.identifyLanguage(chatData: self.chatData)
    }
    
    public init(chatData: WhatsAppChatData) throws {
        self.chatData = chatData
        self.language = try WhatsAppAnalyzer.identifyLanguage(chatData: self.chatData)
    }
    
    public init(chatData: WhatsAppChatData, language: NLLanguage = NLLanguage.english) {
        self.chatData = chatData
        self.language = language
    }
    
    public func getChatData() -> WhatsAppChatData {
        return self.chatData
    }
    
    public func getLanguage() -> NLLanguage {
        return self.language
    }
    
    public func setLanguage(language: NLLanguage) {
        self.language = language
    }
    
    public static func extractChatData(from fileURL: URL) throws -> WhatsAppChatData {
        // Gain access to the chat file
        if !fileURL.startAccessingSecurityScopedResource() {
            throw ChatAnalyzerError.chatFileNoAccess
        }
        
        // Create temporary directory
        let temporaryDirctory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WhatsApp", conformingTo: .directory)
            .appendingPathComponent(UUID().uuidString, conformingTo: .directory)
        do {
            try FileManager.default.createDirectory(at: temporaryDirctory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            os_log("Failed to create temporary directory: %@", type: .error, error.localizedDescription)
            throw ChatAnalyzerError.createDirectoryFailed
        }
        
        // Cleanup
        defer {
            do {
                try FileManager.default.removeItem(at: temporaryDirctory)
            } catch {
                os_log("Failed to remove temporary directory: %@", type: .error, error.localizedDescription)
            }
        }
        
        // Unzip chat data file
        let zipHelper = ZipHelper()
        do {
            try zipHelper.unzipWhatsApp(at: fileURL, to: temporaryDirctory)
        } catch ZipHelperError.chatFileNotFound {
            throw ChatAnalyzerError.invalidChatFile
        } catch {
            throw ChatAnalyzerError.unzipFailed
        }
        
        // Release access
        fileURL.stopAccessingSecurityScopedResource()
        
        // Extract chat data
        do {
            let extractor = try WhatsAppExtractor(chatDataURL: temporaryDirctory)
            let chatData = try extractor.extractChatData()
            return chatData
        } catch {
            os_log("Failed to extract WhatsApp chat data: %@", type: .error, error.localizedDescription)
            throw ChatAnalyzerError.extractDataFailed
        }
    }
    
    public func uniqueUsers() -> Set<String> {
        let users = self.chatData.messages.map { $0.user }
        return Set(users)
    }
    
    public func userCount() -> Int {
        return self.uniqueUsers().count
    }
    
    private func userInChat(user: String) -> Bool {
        let users = self.uniqueUsers()
        return users.contains(user)
    }
    
    private func filterMessage(user: String? = nil, messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> [any ChatMessage] {
        if let user = user {
            if !self.userInChat(user: user) {
                throw ChatAnalyzerError.userNotFound
            }
        }
        
        if let startTime = startTime, let endTime = endTime {
            if startTime > endTime {
                throw WhatsAppAnalyzerError.filterTimeNotValid
            }
        }
        
        let filteredData = self.chatData.messages.filter { message in
            (user == nil ? true : message.user == user!) &&
            (messageType == nil ? true : message.messageType == messageType!) &&
            (startTime == nil ? true : message.timestamp >= startTime!) &&
            (endTime == nil ? true : message.timestamp <= endTime!)
        }
        
        return filteredData
    }
    
    public func uniqueDays(user: String? = nil, messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Set<String> {
        let filteredData = try self.filterMessage(user: user, messageType: messageType, startTime: startTime, endTime: endTime)
        let dates = filteredData.map { $0.timestamp.formatted(date: .numeric, time: .omitted) }
        return Set(dates)
    }
    
    public func uniqueDaysByUser(messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Dictionary<String, Set<String>> {
        var uniqueDays = [String: Set<String>]()
        for user in self.uniqueUsers() {
            uniqueDays[user] = try self.uniqueDays(user: user, messageType: messageType, startTime: startTime, endTime: endTime)
        }
        return uniqueDays
    }
    
    public func dayCount(user: String? = nil, messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Int {
        let uniqueDays = try self.uniqueDays(user: user, messageType: messageType, startTime: startTime, endTime: endTime)
        return uniqueDays.count
    }
    
    public func dayCountByUser(messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Dictionary<String, Int> {
        var dayCount = [String: Int]()
        for user in self.uniqueUsers() {
            dayCount[user] = try self.dayCount(user: user, messageType: messageType, startTime: startTime, endTime: endTime)
        }
        return dayCount
    }
    
    public func messageCount(user: String? = nil, messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Int {
        let filteredData = try self.filterMessage(user: user, messageType: messageType, startTime: startTime, endTime: endTime)
        return filteredData.count
    }
    
    public func messageCountByUser(messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Dictionary<String, Int> {
        var messageCount = [String: Int]()
        for user in self.uniqueUsers() {
            messageCount[user] = try self.messageCount(user: user, messageType: messageType, startTime: startTime, endTime: endTime)
        }
        return messageCount
    }
    
    public func messageCountByFrequency(frequency: Frequency, user: String? = nil, messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Dictionary<DateComponents, Int> {
        let filteredData = try self.filterMessage(user: user, messageType: messageType, startTime: startTime, endTime: endTime)
        let calendar = Calendar.current
        let dates: [DateComponents]
        
        switch frequency {
        case .year:
            dates = filteredData.map { calendar.dateComponents([.calendar, .year], from: $0.timestamp) }
        case .month:
            dates = filteredData.map { calendar.dateComponents([.calendar, .year, .month], from: $0.timestamp) }
        case .week:
            dates = filteredData.map { calendar.dateComponents([.calendar, .year, .weekOfYear], from: $0.timestamp) }
        case .day:
            dates = filteredData.map { calendar.dateComponents([.calendar, .year, .month, .day], from: $0.timestamp) }
        case .weekday:
            dates = filteredData.map { calendar.dateComponents([.calendar, .weekday], from: $0.timestamp) }
        case .hour:
            dates = filteredData.map { calendar.dateComponents([.calendar, .hour], from: $0.timestamp) }
        }
        
        let messageCounts = dates.reduce(into: [:]) { counts, date in
            counts[date, default: 0] += 1
        }
        return messageCounts
    }
    
    public func messageCountByFrequencyByUser(frequency: Frequency, messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Dictionary<String, Dictionary<DateComponents, Int>> {
        var messageCounts = [String: [DateComponents: Int]]()
        for user in self.uniqueUsers() {
            messageCounts[user] = try self.messageCountByFrequency(frequency: frequency, messageType: messageType, startTime: startTime, endTime: endTime)
        }
        return messageCounts
    }
    
    public func messageCountByFrequency(frequencies: [Frequency], user: String? = nil, messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Dictionary<Frequency, [(date: DateComponents, count: Int)]> {
        let filteredData = try self.filterMessage(user: user, messageType: messageType, startTime: startTime, endTime: endTime)
        let calendar = Calendar.current
        
        // Convert timestamp to date components
        var datesByFrequency = [Frequency: [DateComponents]]()
        for frequency in frequencies {
            switch frequency {
            case .year:
                datesByFrequency[frequency] = filteredData.map { calendar.dateComponents([.calendar, .year], from: $0.timestamp) }
            case .month:
                datesByFrequency[frequency] = filteredData.map { calendar.dateComponents([.calendar, .year, .month], from: $0.timestamp) }
            case .week:
                datesByFrequency[frequency] = filteredData.map { calendar.dateComponents([.calendar, .year, .weekOfYear], from: $0.timestamp) }
            case .day:
                datesByFrequency[frequency] = filteredData.map { calendar.dateComponents([.calendar, .year, .month, .day], from: $0.timestamp) }
            case .weekday:
                datesByFrequency[frequency] = filteredData.map { calendar.dateComponents([.calendar, .weekday], from: $0.timestamp) }
            case .hour:
                datesByFrequency[frequency] = filteredData.map { calendar.dateComponents([.calendar, .hour], from: $0.timestamp) }
            }
        }
        
        // Count the message by each frequency
        var messageCountsByFrequency = [Frequency: [(date: DateComponents, count: Int)]]()
        for (frequency, dates) in datesByFrequency {
            let messageCounts = dates.reduce(into: [:]) { counts, date in
                counts[date, default: 0] += 1
            }
                .sorted { $0.key < $1.key }
                .map { date, count in
                    (date: date, count: count)
                }
            messageCountsByFrequency[frequency] = messageCounts
        }
        
        return messageCountsByFrequency
    }
    
    public func messageCountByFrequencyByUser(frequencies: [Frequency], messageType: MessageType? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Dictionary<String, Dictionary<Frequency, [(date: DateComponents, count: Int)]>> {
        var messageCounts = [String: [Frequency: [(date: DateComponents, count: Int)]]]()
        for user in self.uniqueUsers() {
            messageCounts[user] = try self.messageCountByFrequency(frequencies: frequencies, messageType: messageType, startTime: startTime, endTime: endTime)
        }
        return messageCounts
    }
    
    public func wordCount(removeStopWords: Bool = false, user: String?, startTime: Date?, endTime: Date?) throws -> Int {
        let filteredData = try self.filterMessage(user: user, messageType: .text, startTime: startTime, endTime: endTime)
        let messages = filteredData.map { ($0 as! TextMessage).message }
        return try WhatsAppAnalyzer.tokenize(messages: messages, language: self.language, removeStopWords: removeStopWords).count
    }
    
    public func wordCountByUser(removeStopWords: Bool = false, startTime: Date?, endTime: Date?) throws -> Dictionary<String, Int> {
        var wordCount = [String: Int]()
        for user in self.uniqueUsers() {
            wordCount[user] = try self.wordCount(user: user, startTime: startTime, endTime: endTime)
        }
        return wordCount
    }
    
    public func uniqueWordCount(removeStopWords: Bool = false, user: String?, startTime: Date?, endTime: Date?) throws -> Int {
        let filteredData = try self.filterMessage(user: user, messageType: .text, startTime: startTime, endTime: endTime)
        let messages = filteredData.map { ($0 as! TextMessage).message }
        let uniqueWords = Set(try WhatsAppAnalyzer.tokenize(messages: messages, language: self.language, removeStopWords: removeStopWords))
        return uniqueWords.count
    }
    
    public func uniqueWordCountByUser(removeStopWords: Bool = false, startTime: Date?, endTime: Date?) throws -> Dictionary<String, Int> {
        var uniqueWordCount = [String: Int]()
        for user in self.uniqueUsers() {
            uniqueWordCount[user] = try self.uniqueWordCount(user: user, startTime: startTime, endTime: endTime)
        }
        return uniqueWordCount
    }
    
    public func mostCommonWords(n: Int, removeStopWords: Bool = false, user: String?, startTime: Date?, endTime: Date?) throws -> [(word: String, count: Int)] {
        let filteredData = try self.filterMessage(user: user, messageType: .text, startTime: startTime, endTime: endTime)
        let messages = filteredData.map { ($0 as! TextMessage).message }
        let words = try WhatsAppAnalyzer.tokenize(messages: messages, language: self.language, removeStopWords: removeStopWords)
        let wordCounts = words.reduce(into: [:]) { counts, word in
            counts[word, default: 0] += 1
        }
        let sortedWordFrequencies = wordCounts
            .sorted { $0.value > $1.value }
            .map { word, count in
                (word: word, count: count)
            }
        return Array(sortedWordFrequencies.prefix(n))
    }
    
    public func mostCommonWordsByUser(n: Int, removeStopWords: Bool = false, startTime: Date?, endTime: Date?) throws -> [(user: String, mostCommonWords: [(word: String, count: Int)])] {
        var mostCommonWords = [(user: String, mostCommonWords: [(word: String, count: Int)])]()
        for user in self.uniqueUsers() {
            let userMostCommonWords = try self.mostCommonWords(n: n, removeStopWords: removeStopWords, user: user, startTime: startTime, endTime: endTime)
            mostCommonWords.append((user: user, mostCommonWords: userMostCommonWords))
        }
        return mostCommonWords
    }
    
    public func emojiCount(user: String?, startTime: Date?, endTime: Date?) throws -> Int {
        let filteredData = try self.filterMessage(user: user, messageType: .text, startTime: startTime, endTime: endTime)
        let emojiCount = filteredData
            .map { ($0 as! TextMessage).message.emojiCount }
            .reduce(0, +)
        return emojiCount
    }
    
    public func emojiCountByUser(startTime: Date?, endTime: Date?) throws -> Dictionary<String, Int> {
        var emojiCounts = [String: Int]()
        for user in self.uniqueUsers() {
            emojiCounts[user] = try self.emojiCount(user: user, startTime: startTime, endTime: endTime)
        }
        return emojiCounts
    }
    
    public func uniqueEmojiCount(user: String?, startTime: Date?, endTime: Date?) throws -> Int {
        let filteredData = try self.filterMessage(user: user, messageType: .text, startTime: startTime, endTime: endTime)
        let emojis = filteredData
            .map { ($0 as! TextMessage).message.emojis }
            .joined()
        let uniqueEmojis = Set(emojis)
        return uniqueEmojis.count
    }
    
    public func uniqueEmojiCountByUser(startTime: Date?, endTime: Date?) throws -> Dictionary<String, Int> {
        var uniqueEmojiCount = [String: Int]()
        for user in self.uniqueUsers() {
            uniqueEmojiCount[user] = try self.uniqueEmojiCount(user: user, startTime: startTime, endTime: endTime)
        }
        return uniqueEmojiCount
    }
    
    public func mostCommonEmojis(n: Int, user: String?, startTime: Date?, endTime: Date?) throws -> [(emoji: Character, count: Int)] {
        let filteredData = try self.filterMessage(user: user, messageType: .text, startTime: startTime, endTime: endTime)
        let emojis = filteredData.map { ($0 as! TextMessage).message.emojis }.joined()
        let emojiCounts = emojis.reduce(into: [:]) { counts, emoji in
            counts[emoji, default: 0] += 1
        }
        let sortedEmojiCounts = emojiCounts
            .sorted { $0.value > $1.value }
            .map { emoji, count in
                (emoji: emoji, count: count)
            }
        return Array(sortedEmojiCounts.prefix(n))
    }
    
    public func mostCommonEmojisByUser(n: Int, startTime: Date?, endTime: Date?) throws -> Dictionary<String, [(emoji: Character, count: Int)]> {
        var mostCommonEmojis = [String: [(emoji: Character, count: Int)]]()
        for user in self.uniqueUsers() {
            mostCommonEmojis[user] = try self.mostCommonEmojis(n: n, user: user, startTime: startTime, endTime: endTime)
        }
        return mostCommonEmojis
    }
    
    public func analyzeSentiment() throws -> [any ChatMessage] {
        let sentimentAnalyzer = try SentimentAnalyzer(modelType: .StaticSST2)
        for i in 0..<self.chatData.messages.count {
            if self.chatData.messages[i].messageType == .text {
                var textMessage = self.chatData.messages[i] as! TextMessage
                textMessage.sentimentLabel = sentimentAnalyzer.analyzeSentiment(for: textMessage)
                self.chatData.messages[i] = textMessage
            }
        }
        self.chatData.isSentimentAnalyzed = true
        return self.chatData.messages
    }
    
    public func analyzeSentimentByFrequency(frequency: Frequency, user: String?, startTime: Date?, endTime: Date?) throws -> [(date: DateComponents, sentimentCounts: [(sentiment: String, count: Int)])] {
        // Perform sentiment analysis if the messages aren't analyzed
        if !self.chatData.isSentimentAnalyzed {
            _ = try self.analyzeSentiment()
        }
        
        // Filter text messages
        let filteredData = try self.filterMessage(user: user, messageType: .text, startTime: startTime, endTime: endTime)
        let textMessages = filteredData.map { $0 as! TextMessage }
        
        // Count the sentiment labels by given frequency
        let sentimentFrequencies = try WhatsAppAnalyzer.calculateSentimentCount(messages: textMessages, frequency: frequency, calendar: Calendar.current)
        return sentimentFrequencies
    }
    
    public func analyzeSentimentByFrequency(frequencies: [Frequency], user: String?, startTime: Date?, endTime: Date?) throws -> Dictionary<Frequency, [(date: DateComponents, sentimentCounts: [(sentiment: String, count: Int)])]> {
        // Perform sentiment analysis if the messages aren't analyzed
        if !self.chatData.isSentimentAnalyzed {
            _ = try self.analyzeSentiment()
        }
        
        // Filter text messages
        let filteredData = try self.filterMessage(user: user, messageType: .text, startTime: startTime, endTime: endTime)
        let textMessages = filteredData.map { $0 as! TextMessage }
        
        // Count the sentiment labels for each given frequency
        var sentimentCountByFrequency = [Frequency: [(date: DateComponents, sentimentCounts: [(sentiment: String, count: Int)])]]()
        for frequency in frequencies {
            let sentimentFrequencies = try WhatsAppAnalyzer.calculateSentimentCount(messages: textMessages, frequency: frequency, calendar: Calendar.current)
            sentimentCountByFrequency[frequency] = sentimentFrequencies
        }
        
        return sentimentCountByFrequency
    }
    
    public func longestMessage(user: String? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Int {
        let filteredData = try self.filterMessage(user: user, messageType: .text, startTime: startTime, endTime: endTime)
        let messages = filteredData.map { ($0 as! TextMessage).message }
        if let longestMessage = messages.max(by: { $0.count < $1.count }) {
            return longestMessage.count
        } else {
            return 0
        }
    }
    
    public func longestMessageByUser(startTime: Date? = nil, endTime: Date? = nil) throws -> [String: Int] {
        var longestMessage = [String: Int]()
        for user in self.uniqueUsers() {
            longestMessage[user] = try self.longestMessage(user: user)
        }
        return longestMessage
    }
    
    public func chatDuration(user: String? = nil) throws -> DateInterval {
        let filteredData = try self.filterMessage(user: user, messageType: .text)
        let textMessages = filteredData.map { $0 as! TextMessage }
        return try WhatsAppAnalyzer.calculateChatDuration(messages: textMessages)
    }
    
    public func chatDurationByUser() throws -> [String: DateInterval] {
        var chatDuration = [String: DateInterval]()
        for user in self.uniqueUsers() {
            chatDuration[user] = try self.chatDuration(user: user)
        }
        return chatDuration
    }
    
    public func averageMessageLength(user: String? = nil, startTime: Date? = nil, endTime: Date? = nil) throws -> Double {
        let filteredData = try self.filterMessage(user: user, messageType: .text, startTime: startTime, endTime: endTime)
        let messages = filteredData.map { ($0 as! TextMessage).message }
        return try WhatsAppAnalyzer.calculateAverageMessageLength(messages: messages)
    }
    
    public func averageMessageLengthByUser(startTime: Date? = nil, endTime: Date? = nil) throws -> [String: Double] {
        var averageMessageLength = [String: Double]()
        for user in self.uniqueUsers() {
            averageMessageLength[user] = try self.averageMessageLength(user: user, startTime: startTime, endTime: endTime)
        }
        return averageMessageLength
    }
    
    public func averageReplyTime(user: String, startTime: Date? = nil, endTime: Date? = nil) throws -> TimeInterval {
        let filteredData = try self.filterMessage(messageType: .text, startTime: startTime, endTime: endTime)
        let textMessages = filteredData.map { $0 as! TextMessage }
        return try WhatsAppAnalyzer.calculateAverageReplyTime(messages: textMessages, user: user)
    }
    
    public func averageReplyTimeByUser(startTime: Date? = nil, endTime: Date? = nil) throws -> [String: TimeInterval] {
        let filteredData = try self.filterMessage(messageType: .text, startTime: startTime, endTime: endTime)
        let textMessages = filteredData.map { $0 as! TextMessage }
        var averageMessageLength = [String: TimeInterval]()
        for user in self.uniqueUsers() {
            averageMessageLength[user] = try WhatsAppAnalyzer.calculateAverageReplyTime(messages: textMessages, user: user)
        }
        return averageMessageLength
    }
}

public enum WhatsAppAnalyzerError: Error {
    case filterTimeNotValid
}

extension WhatsAppAnalyzerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case.filterTimeNotValid:
            return NSLocalizedString("endTime should be equal to or greater than startTime.", comment: "Filter Time Not Valid")
        }
    }
}

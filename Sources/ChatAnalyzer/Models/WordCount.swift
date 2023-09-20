//
//  WordCount.swift
//
//
//  Created by Junpeng Chen on 14.09.23.
//

import Foundation

public struct WordCount: Codable, Hashable {
    public let word: String
    public let count: Int
}

public struct UserWordCounts: Codable, Hashable {
    public let user: String
    public let wordCounts: [WordCount]
}

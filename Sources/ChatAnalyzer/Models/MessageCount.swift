//
//  MessageCount.swift
//
//
//  Created by Junpeng Chen on 17.09.23.
//

import Foundation

public struct MessageCount: Codable, Hashable {
    public let date: DateComponents
    public let count: Int
}

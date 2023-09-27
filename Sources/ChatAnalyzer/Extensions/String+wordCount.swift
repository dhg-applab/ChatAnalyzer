//
//  String+wordCount.swift
//
//
//  Created by Junpeng Chen on 28.09.23.
//

import Foundation

extension String {
    var wordCount: Int {
        var count = 0
        enumerateSubstrings(in: startIndex..<endIndex, options: [.byWords, .substringNotRequired, .localized]) {_, _, _, _ in
            count += 1
        }
        return count
    }
}

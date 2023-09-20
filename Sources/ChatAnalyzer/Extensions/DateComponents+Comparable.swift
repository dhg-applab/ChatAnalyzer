//
//  DateComponents+Comparable.swift
//
//
//  Created by Junpeng Chen on 12.09.23.
//

import Foundation

// From https://stackoverflow.com/a/64516065
extension DateComponents: Comparable {
    public static func < (lhs: DateComponents, rhs: DateComponents) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        return calendar.date(byAdding: lhs, to: now)! < calendar.date(byAdding: rhs, to: now)!
    }
}

//
//  DateComponents+toString.swift
//
//
//  Created by Junpeng Chen on 18.09.23.
//

import Foundation

extension DateComponents {
    public func toString(frequency: Frequency) -> String {
        switch frequency {
        case .year:
            guard let year = self.year else {
                return ""
            }
            return String(year)
        case .month:
            guard let month = self.month, let year = self.year else {
                return ""
            }
            return "\(month)/\(year)"
        case .week:
            guard let weekOfYear = self.weekOfYear, let year = self.year else {
                return ""
            }
            return "\(weekOfYear)/\(year)"
        case .day:
            guard let day = self.day, let month = self.month, let year = self.year else {
                return ""
            }
            return "\(day)/\(month)/\(year)"
        case .weekday:
            guard let weekday = self.weekday else {
                return ""
            }
            return Calendar.current.weekdaySymbols[weekday - 1]
        case .hour:
            guard let hour = self.hour else {
                return ""
            }
            return String(hour)
        }
    }
}

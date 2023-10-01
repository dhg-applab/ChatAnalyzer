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
        case .hour:
            guard let hour = self.hour, let day = self.day, let month = self.month, let year = self.year else {
                return ""
            }
            return "\(day)/\(month)/\(year) \(hour)"
        case .weekday:
            guard let weekday = self.weekday else {
                return ""
            }
            return Calendar.current.weekdaySymbols[weekday - 1]
        case .hourOfDay:
            guard let hour = self.hour else {
                return ""
            }
            if hour == 0 {
                return "00-01"
            } else if hour == 23 {
                return "23-24"
            } else {
                return String(format: "%02d-%02d", hour, hour+1)
            }
        }
    }
}

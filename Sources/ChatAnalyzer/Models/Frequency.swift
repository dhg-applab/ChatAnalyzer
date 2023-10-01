//
//  Frequency.swift
//  
//
//  Created by Junpeng Chen on 07.09.23.
//

import Foundation

public enum Frequency: String, CaseIterable, Codable, CustomStringConvertible, CodingKey {
    case year
    case month
    case week
    case day
    case weekday
    case hourOfDay
    
    public var description: String {
      switch self {
      case .year: return "Year"
      case .month: return "Month"
      case .week: return "Week"
      case .day: return "Day"
      case .weekday: return "Weekday"
      case .hourOfDay: return "Hour of day"
      }
    }
    
    public var calendarComponent: Calendar.Component {
        switch self {
        case .year: return .year
        case .month: return .month
        case .week: return .weekOfYear
        case .day: return .day
        case .weekday: return .weekday
        case .hourOfDay: return .hour
        }
    }
}

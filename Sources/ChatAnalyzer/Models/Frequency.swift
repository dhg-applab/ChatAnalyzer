//
//  Frequency.swift
//  
//
//  Created by Junpeng Chen on 07.09.23.
//

public enum Frequency: CaseIterable, Codable, CustomStringConvertible {
    case year
    case month
    case week
    case day
    case weekday
    case hour
    
    public var description : String {
      switch self {
      case .year: return "Year"
      case .month: return "Month"
      case .week: return "Week"
      case .day: return "Day"
      case .weekday: return "Weekday"
      case .hour: return "Hour"
      }
    }
}

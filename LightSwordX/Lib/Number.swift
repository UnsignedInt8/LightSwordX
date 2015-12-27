//
//  Number.swift
//  LightSwordX
//
//  Created by Neko on 12/27/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Foundation

class StatisticsHelper {
    
    private static let KB: Double = 1024
    private static let MB = 1024 * KB
    private static let GB = 1024 * MB
    private static let TB = 1024 * GB
    private static var formatter: NSNumberFormatter!
    
    static func toStatisticsString(number: UInt64) -> (value: Double, unit: String, formattedString: String) {
        if formatter == nil {
            formatter = NSNumberFormatter()
            formatter.numberStyle = .DecimalStyle
        }
        
        var value = Double(number)
        var unit = "Bytes"
        formatter.format = "0.00"
        
        switch value {
        case let v where v > TB:
            value = value / TB
            unit = "TB"
            break
            
        case let v where v > GB && v <= TB:
            value = value / GB
            unit = "GB"
            break
            
        case let v where v > MB && v <= GB:
            value = value / MB
            unit = "MB"
            break
            
        case let v where v > KB && v <= MB:
            value = value / KB
            unit = "KB"
            break
            
        default:
            formatter.format = "0"
            break
        }
        
        let formatted = "\(formatter.stringFromNumber(NSNumber(double: value))!) \(unit)"
        return (value: value, unit: unit, formattedString: formatted)
    }
}

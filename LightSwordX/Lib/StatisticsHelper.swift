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
    
    static func toStatisticsString(number: UInt64) -> (value: Double, formattedValue: String, unit: String) {
        if formatter == nil {
            formatter = NSNumberFormatter()
            formatter.numberStyle = .DecimalStyle
        }
        
        var value = Double(number)
        var unit = "Bytes"
        formatter.format = "0.0#"
        
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
        
        return (value: value, formattedValue: formatter.stringFromNumber(value)!, unit: unit)
    }
    
    static func getUptimeInMilliseconds() -> UInt64 {
        let kOneMillion: UInt64 = 1000 * 1000;
        var s_timebase_info = mach_timebase_info_data_t();
        
        if (s_timebase_info.denom == 0) {
            mach_timebase_info(&s_timebase_info);
        }
        
        // mach_absolute_time() returns billionth of seconds,
        // so divide by one million to get milliseconds
        return mach_absolute_time() * UInt64(s_timebase_info.numer) / (kOneMillion * UInt64(s_timebase_info.denom))
    }
}

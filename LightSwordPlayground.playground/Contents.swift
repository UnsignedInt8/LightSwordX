//: Playground - noun: a place where people can play

import Cocoa

let bytes1: [UInt8] = [0x1, 0x2, 0x3, 0x4]
let xr = UInt8(arc4random() % 256)
let bytesXor = bytes1.map({ n in n ^ xr })
let bytesRaw = bytesXor.map({ n in n ^ xr })
assert(bytesRaw[0] == bytes1[0])

func getUptimeInMilliseconds() -> UInt64
{
    let kOneMillion: UInt64 = 1000 * 1000;
    var s_timebase_info = mach_timebase_info_data_t();
    
    if (s_timebase_info.denom == 0) {
        mach_timebase_info(&s_timebase_info);
    }
    
    // mach_absolute_time() returns billionth of seconds,
    // so divide by one million to get milliseconds
    return mach_absolute_time() * UInt64(s_timebase_info.numer) / (kOneMillion * UInt64(s_timebase_info.denom))
}

let start = getUptimeInMilliseconds()

class StatisticsHelper {
    
    private static let KB: Double = 1024
    private static let MB = 1024 * KB
    private static let GB = 1024 * MB
    private static let TB = 1024 * GB
    private static var formatter: NSNumberFormatter!
    
    static func toStatisticsString(number: UInt64) -> String {
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
        
        return "\(formatter.stringFromNumber(NSNumber(double: value))!) \(unit)"
    }
}

StatisticsHelper.toStatisticsString(1025000000)

getUptimeInMilliseconds() - start




public func getLoginItems() -> LSSharedFileList? {
    let allocator : CFAllocator! = CFAllocatorGetDefault().takeUnretainedValue()
    let kLoginItems : CFString! = kLSSharedFileListSessionLoginItems.takeUnretainedValue()
    var loginItems_ = LSSharedFileListCreate(allocator, kLoginItems, nil)
    if loginItems_ == nil {return nil}
    let loginItems : LSSharedFileList! = loginItems_.takeRetainedValue()
    return loginItems
}

public func existingItem(itemURL : NSURL) -> LSSharedFileListItem? {
    let loginItems_ = getLoginItems()
    if loginItems_ == nil {return nil}
    let loginItems = loginItems_!
    
    var seed : UInt32 = 0
    let currentItems = LSSharedFileListCopySnapshot(loginItems, &seed).takeRetainedValue() as NSArray
    
    for item in currentItems {
        let resolutionFlags : UInt32 = UInt32(kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes)
        var url = LSSharedFileListItemCopyResolvedURL(item as! LSSharedFileListItem, resolutionFlags, nil).takeRetainedValue() as NSURL
        if url.isEqual(itemURL) {
            let result = item as! LSSharedFileListItem
            return result
        }
    }
    
    return nil
}

public func willLaunchAtLogin(itemURL : NSURL) -> Bool {
    return existingItem(itemURL) != nil
}

public func setLaunchAtLogin(itemURL: NSURL, enabled: Bool) -> Bool {
    let loginItems_ = getLoginItems()
    if loginItems_ == nil {return false}
    let loginItems = loginItems_!
    
    var item = existingItem(itemURL)
    if item != nil && enabled {return true}
    if item != nil && !enabled {
        LSSharedFileListItemRemove(loginItems, item)
        return true
    }
    
    LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst.takeUnretainedValue(), nil, nil, itemURL as CFURL, nil, nil)
    return true
}

print(getLoginItems())
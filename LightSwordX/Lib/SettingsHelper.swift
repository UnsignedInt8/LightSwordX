//
//  UserDefaultsHelper.swift
//  LightSwordX
//
//  Created by Neko on 12/23/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Foundation

public class SettingsHelper {
    
    private static let defaults = NSUserDefaults.standardUserDefaults()
    
    public class func saveValue<T: AnyObject>(value: T, forKey key: String) {
        defaults.setValue(value, forKey: key)
    }
    
    public class func loadValue<T>(defaultValue defaultValue: T, forKey key: String) -> T {
        let value: AnyObject? = defaults.objectForKey(key)
        if let v: AnyObject = value {
            return v as! T
        }
        
        return defaultValue
    }
    
    public class func loadValueForKey<T>(key: String) -> T! {
        return loadValue(defaultValue: nil, forKey: key)
    }
    
    public class func removeValueForKey(key: String) {
        defaults.removeObjectForKey(key)
    }
    
    public class func reset() {
        NSUserDefaults.resetStandardUserDefaults()
    }
    
    public class func synchronize() {
        defaults.synchronize()
    }
}
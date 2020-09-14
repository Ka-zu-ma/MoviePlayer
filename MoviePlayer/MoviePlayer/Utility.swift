//
//  Utility.swift
//  MoviePlayer
//
//  Created by 宮崎数磨 on 2020/09/11.
//  Copyright © 2020 宮崎数磨. All rights reserved.
//

import Foundation

class Utility {
    //  TimeIntervalをStringに変換
    static func timeToString(time: TimeInterval) -> String{
        let second: Int
        let minute: Int
        second = Int(time) % 60
        minute = Int(time) / 60
        return "\(minute):\(NSString(format: "%02d", second))"
    }
}

//
//  Item.swift
//  GPSlog
//
//  Created by Tamura Kyoco on 2025/12/02.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

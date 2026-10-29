//
//  Item.swift
//  Did-I
//
//  Created by Jiren Patel on 29/10/26.
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

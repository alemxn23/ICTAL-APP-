//
//  Item.swift
//  Epilepsia APP
//
//  Created by Macbook Pro on 16/02/26.
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

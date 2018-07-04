//
//  Character+UInt32.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/4/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter{$0.isASCII}.first?.value
    }
}

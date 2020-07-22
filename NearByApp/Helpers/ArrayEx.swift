//
//  ArrayEx.swift
//  NearByApp
//
//  Created by kholy on 7/20/20.
//  Copyright © 2020 kholy. All rights reserved.
//

import Foundation

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        return result
    }
}

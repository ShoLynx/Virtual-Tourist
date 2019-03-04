//
//  EResponse.swift
//  Virtual Tourist
//
//  Created by Administrator on 2/18/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation


struct EResponse: Codable {
    let stat: String
    let code: Int
    let message: String
}

extension EResponse: LocalizedError {
    var errorMessage: String? {
        return message
    }
}

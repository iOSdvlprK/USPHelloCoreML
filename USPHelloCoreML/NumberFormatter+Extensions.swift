//
//  NumberFormatter+Extensions.swift
//  USPHelloCoreML
//
//  Created by joe on 10/22/25.
//

import Foundation

extension NumberFormatter {
    static var percentage: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

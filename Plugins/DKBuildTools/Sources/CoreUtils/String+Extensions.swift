//
//  String+Extensions.swift
//  
//
//  Created by Shahzad Majeed on 12/26/22.
//

import Foundation

// MARK: String Extensions
public extension String {
    
    /// Capitalize first letter of a string
    var firstLetterUpperCase: String {
        prefix(1).capitalized + dropFirst()
    }
}

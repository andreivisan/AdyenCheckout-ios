//
//  Payment.swift
//  Pods
//
//  Created by Oleg Lutsenko on 7/1/16.
//
//

import UIKit

public class Payment: NSObject {
    
    let amount: Int
    let currency: String
    let merchantReference: String?
    let country: String
    
    public init(amount: Int, currency: String, merchantReference: String?, country: String) {
        self.amount = amount
        self.currency = currency
        self.merchantReference = merchantReference
        self.country = country
    }

}

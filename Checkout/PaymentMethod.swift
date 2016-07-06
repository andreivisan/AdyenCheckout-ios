//
//  PaymentMethod.swift
//  Pods
//
//  Created by Oleg Lutsenko on 7/1/16.
//
//

import UIKit

public enum PaymentMethodType {
    case CreditCard
    case iDEAL
    case Other
}

public class PaymentMethod: NSObject {
    
    let type: PaymentMethodType
    public let name: String
    let brandCode: String
    let issuerId: String?
    
    public init(type: PaymentMethodType, name: String, brandCode: String, issuerId: String?) {
        self.type = type
        self.name = name
        self.brandCode = brandCode
        self.issuerId = issuerId
    }

    override public var debugDescription: String {
        return brandCode + " / " + name
    }
}

//public class CardPaymentMethod: PaymentMethod {
//    let type = PaymentMethodType.CreditCard
//}
//
//public class IDealPaymentMethod: PaymentMethod {
//    let type = PaymentMethodType.iDEAL
//    let issuerId: String
//    
//    public init(name: String, brandCode: String, issuerId: String) {
//        self.issuerId = issuerId
//        super.init(name: name, brandCode: brandCode)
//    }
//}
//
//public class OtherPaymentMethod: PaymentMethod {
//    let type = PaymentMethodType.Other
//}
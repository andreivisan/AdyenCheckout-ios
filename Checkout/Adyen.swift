//
//  Adyen.swift
//  Pods
//
//  Created by Oleg Lutsenko on 7/1/16.
//
//

import UIKit

public typealias PaymentMethodsCollection = [PaymentMethodType: [PaymentMethod]]

public class Adyen: NSObject {
    
    let merchantAPIURL: NSURL
    let session: NSURLSession
    
    public init(merchantAPIURL: NSURL) {
        self.merchantAPIURL = merchantAPIURL
        self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    }
    
    public func fetchPaymentMethodsFor(paymentRequest: Payment, completion: (PaymentMethodsCollection?, NSError?) -> ()) {
        
        let endpoint = "api.php?action=getMethods"
        
        let fullUrl = NSURL(string: self.merchantAPIURL.absoluteString + "/" + endpoint)
        let urlComponents = NSURLComponents(URL: fullUrl!, resolvingAgainstBaseURL: true)

        var queryItems = urlComponents?.queryItems
        queryItems?.append(NSURLQueryItem(name: "paymentAmount", value: String(paymentRequest.amount)))
        queryItems?.append(NSURLQueryItem(name: "currencyCode", value: paymentRequest.currency))
        queryItems?.append(NSURLQueryItem(name: "merchantReference", value:paymentRequest.merchantReference))
        queryItems?.append(NSURLQueryItem(name: "countryCode", value: paymentRequest.country))
        urlComponents?.queryItems = queryItems
        
        let request = NSMutableURLRequest(URL: (urlComponents?.URL)!)
        request.HTTPMethod = "GET"
        
        self.session.dataTaskWithRequest(request) { (data, response, error) in
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                return
            }
            
            guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String: String] else {
                return
            }

            guard let queryString = self.queryString(json) else {
                return
            }
            
            let endpoint = "api.php?action=getMethods"
            
            let url = NSURL(string: "https://test.adyen.com/hpp/directory.shtml")!
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.HTTPBody = queryString.dataUsingEncoding(NSUTF8StringEncoding)
            
            self.session.dataTaskWithRequest(
                request,
                completionHandler: { (data, _, error) in
                    
                    guard let data = data else {
                        return
                    }
                    
                    var cardPayments = [PaymentMethod]()
                    var iDealPayments = [PaymentMethod]()
                    var otherPayments = [PaymentMethod]()
                    
                    let cardBrandCodes = [
                        "diners",
                        "discover",
                        "amex",
                        "mc",
                        "visa",
                        "maestro"
                    ]
                    
                    let iDealBrandCode = "ideal"
                    
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String: AnyObject]
                        
                        let paymentMethodsInfo = json["paymentMethods"] as! [AnyObject]
                        
                        
                        for payment in paymentMethodsInfo {
                            let paymentInfo = payment as! [String: AnyObject]
                            
                            let brandCode = paymentInfo["brandCode"] as! String
                            let name = paymentInfo["name"] as! String
                            
                            //  Card Payment?
                            var isCardPayment = false
                            for code in cardBrandCodes {
                                if code == brandCode {
                                    isCardPayment = true
                                    break
                                }
                            }
                            if isCardPayment {
                                cardPayments.append(PaymentMethod(type: .CreditCard, name: name, brandCode: brandCode, issuerId: nil))
                                continue
                            }
                            
                            //  iDeal Payment?
                            if brandCode == iDealBrandCode {
                                let issuersInfo = paymentInfo["issuers"] as! [[String: AnyObject]]
                                for issuer in issuersInfo {
                                    let issuerId = issuer["issuerId"] as! String
                                    let name = issuer["name"] as! String
                                    iDealPayments.append(PaymentMethod(type: .iDEAL, name: name, brandCode: brandCode, issuerId: issuerId))
                                }
                                continue
                            }
                            
                            //  Other payment?
                            otherPayments.append(PaymentMethod(type: .Other, name: name, brandCode: brandCode, issuerId: nil))
                        }
                        
                        let paymentsCollection = [PaymentMethodType.CreditCard: cardPayments,
                            PaymentMethodType.iDEAL: iDealPayments,
                            PaymentMethodType.Other: otherPayments
                        ]
                        
                        completion(paymentsCollection, nil)
                        
                    } catch let error as NSError {
                        completion(nil, error)
                        return
                    }
                    
            }).resume()

            
            
            
        }.resume()
    }

    public func fetchPaymentRedirectURLFor(payment: Payment, payWith method: PaymentMethod, completionHandler: (NSURL?, NSError?) -> ()) {
        let endpoint = "api.php?action=getRedirect"
        
        let fullUrl = NSURL(string: self.merchantAPIURL.absoluteString + "/" + endpoint)
        let urlComponents = NSURLComponents(URL: fullUrl!, resolvingAgainstBaseURL: true)
        
        var queryItems = urlComponents?.queryItems
        queryItems?.append(NSURLQueryItem(name: "paymentAmount", value: String(payment.amount)))
        queryItems?.append(NSURLQueryItem(name: "currencyCode", value: payment.currency))
        queryItems?.append(NSURLQueryItem(name: "merchantReference", value:payment.merchantReference))
        queryItems?.append(NSURLQueryItem(name: "countryCode", value: payment.country))
        
        queryItems?.append(NSURLQueryItem(name: "brandCode", value: method.brandCode))
        if let issuerId = method.issuerId {
            queryItems?.append(NSURLQueryItem(name: "issuerId", value: issuerId))
        }
        
        urlComponents?.queryItems = queryItems
        
        let request = NSMutableURLRequest(URL: (urlComponents?.URL)!)
        request.HTTPMethod = "GET"
        
        self.session.dataTaskWithRequest(request) { (data, _, error) in
            
            if let error = error {
                completionHandler(nil, error)
                return
            }
            
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            
            guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String: String] else {
                completionHandler(nil, nil)
                return
            }
            
            let query = self.queryString(json)
            
            let url = NSURL(string: "https://test.adyen.com/hpp/skipDetails.shtml")!
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.HTTPBody = query?.dataUsingEncoding(NSUTF8StringEncoding)
            
            self.session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                completionHandler(response?.URL, error)                
            }).resume()
            
        }.resume()

    }
    
    func queryString(items: [String: String]) -> String? {
        var allowedCharacters = NSMutableCharacterSet.URLHostAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        allowedCharacters.removeCharactersInString("+:=")

        var queryString = ""
        for (key, value) in items {
            guard let value = value.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters) else {
                return nil
            }
            
            queryString = queryString + key + "=" + value + "&"
        }
        
        return queryString
    }
    
}

extension Adyen: NSURLSessionDelegate {

}

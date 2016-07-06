//
//  TestPaymentViewController.swift
//  AdyenCheckout
//
//  Created by Oleg Lutsenko on 7/1/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SafariServices
import AdyenCheckout

class TestPaymentViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    @IBAction func test(sender: AnyObject) {
        let vc = PaymentPickerViewController(style: .Plain)
        let navController = UINavigationController(rootViewController: vc)
        self.presentViewController(navController, animated: true, completion: nil)
    }
    
    
    @IBAction func testPaymentAction(sender: AnyObject) {

        guard let url = NSURL(string: "http://www.mozuma.nl/adyen") else {
            return
        }
        
        let adyen = Adyen(merchantAPIURL: url)
        
        let payment = Payment(
            amount: 500,
            currency: "EUR",
            merchantReference: "test_payment",
            country: "NL");
        
        adyen.fetchPaymentMethodsFor(payment) { (paymentMethods, error) in
            
            if error != nil {
                //  process error
                return
            }
            
            guard let paymentMethods = paymentMethods else {
                return
            }
            
            //  Present payment methods UI
            
            
            
            guard let method = paymentMethods[PaymentMethodType.iDEAL]?[0] else { return }
            
            adyen.fetchPaymentRedirectURLFor(payment, payWith: method, completionHandler: { (url, error) in
                
                print(url)
                
                guard let url = url else {
                    return
                }
                
                let vc = SFSafariViewController(URL: url, entersReaderIfAvailable: false)
                vc.modalPresentationStyle = .FormSheet
                self.presentViewController(vc, animated: true, completion: nil)
                
            })
            
            
            
            
            
        }
    }
    
}

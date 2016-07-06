//
//  PaymentPickerViewController.swift
//  AdyenCheckout
//
//  Created by Oleg Lutsenko on 7/5/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SafariServices
import AdyenCheckout

class PaymentPickerViewController: LoadingTableViewController {
    
    var paymentMethods: PaymentMethodsCollection?
    
    var adyenAPI: Adyen?
    var payment: Payment?
    
    var safariViewController: SFSafariViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = NSURL(string: "http://www.mozuma.nl/adyen")!
        adyenAPI = Adyen(merchantAPIURL: url)

        title = "Select Payment"
        loading = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Cancel,
            target: self,
            action: Selector("cancelPayment"))
        
        tableView.registerClass(LoadingTableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("receivedUrlNotification"),
            name: openUrlNotification,
            object: nil)
        
        fetchPayments()
    }
    
    func receivedUrlNotification() {
        guard let viewController = safariViewController else {
            return
        }
        
        viewController.dismissViewControllerAnimated(true) { 
//            self.dismissViewControllerAnimated(false, completion: nil)
            
            let alertController = UIAlertController(
                title: "Payment Result URL",
                message: receivedUrl?.absoluteString,
                preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (_) in
                alertController.dismissViewControllerAnimated(true, completion: nil)
            }))
                
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func cancelPayment() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func fetchPayments() {
        
        payment = Payment(
            amount: 500,
            currency: "EUR",
            merchantReference: "test_payment",
            country: "NL");
        
        adyenAPI!.fetchPaymentMethodsFor(payment!) { (payments, error) in
            guard let paymentMethods = payments else {
                return
            }
            
            self.paymentMethods = paymentMethods
            self.loading = false
            
            dispatch_async(dispatch_get_main_queue(), { 
                self.tableView.reloadData()
            })
            
        }

    }
    
    func paymentMethod(at: NSIndexPath) -> PaymentMethod? {
        guard let paymentMethods = paymentMethods else {
            return nil
        }
        
        var method: PaymentMethod?
        switch at.section {
        case 0:
            method = paymentMethods[.CreditCard]?[at.row]
            break
        case 1:
            method = paymentMethods[.iDEAL]?[at.row]
            break
        case 2:
            method = paymentMethods[.Other]?[at.row]
            break
        default:
            method = nil
            break
        }
        
        return method
    }

}

extension PaymentPickerViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if paymentMethods == nil {
            return 0
        }

        return 3
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil
        switch section {
        case 0:
            title = "Credit Card"
            break
        case 1:
            title = "iDEAL"
            break
        case 2:
            title = "Other"
            break
        default:
            break
        }
        
        return title
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let methods = paymentMethods else {
            return 0
        }

        var count = 0
        switch section {
        case 0:
            count = methods[.CreditCard]!.count
            break
        case 1:
            count = methods[.iDEAL]!.count
            break
        case 2:
            count = methods[.Other]!.count
            break
        default:
            count = 0
        }

        return count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        if let method = paymentMethod(indexPath) {
            cell.textLabel?.text = method.name
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let paymentMethod = paymentMethod(indexPath) else {
            return
        }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as? LoadingTableViewCell
        if let cell = cell {
            cell.startLoadingAnimation()
        }
        
        adyenAPI!.fetchPaymentRedirectURLFor(
            payment!,
            payWith: paymentMethod) { (url, error) in
                
                if let cell = cell {
                    cell.stopLoadingAnimation()
                }
                
                if let error = error {
                    //  handle error
                    print(error)
                    return
                }
                
                guard let url = url else {
                    return
                }
                
                self.safariViewController = SFSafariViewController(URL: url)
                self.safariViewController?.modalPresentationStyle = .FormSheet
                self.presentViewController(self.safariViewController!, animated: true, completion: nil)
        }
        
    }
    
}

class LoadingTableViewCell: UITableViewCell {
    let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryView = loadingIndicator
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startLoadingAnimation() {
        dispatch_async(dispatch_get_main_queue()) { 
            self.loadingIndicator.startAnimating()
        }
    }
    
    func stopLoadingAnimation() {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingIndicator.stopAnimating()
        }
    }
}
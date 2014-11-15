//
//  ConfigureScanNameViewController.swift
//  BlueCap
//
//  Created by chris clogg on 2014-11-14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth

class ConfigureScanNameViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField : UITextField!
    @IBOutlet var doNotDisplayWithoutNameSwitch : UISwitch!
    
    var serviceName             : String?
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let serviceName = self.serviceName {
            self.nameTextField.text = serviceName
            if let doNotDisplayWithoutName = ConfigStore.getScannedNameBool(serviceName) {
                self.doNotDisplayWithoutNameSwitch.on = doNotDisplayWithoutName
            }
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.nameTextField.resignFirstResponder()
        return true
    }
    
    @IBAction func toggleDoNotDisplayDeviceWithoutName(sender:AnyObject) {
    }
    
    @IBAction func doneTapped(sender:AnyObject) {
        let enteredName = self.nameTextField.text
        let doNotDisplayDevicesWithoutName = self.doNotDisplayWithoutNameSwitch.on
        if enteredName != nil
        {
            if !enteredName!.isEmpty
            {
                if let serviceName = self.serviceName
                {
                    // updating
                    ConfigStore.addScannedName(enteredName!, doNotDisplayWithoutName: doNotDisplayDevicesWithoutName)
                    if serviceName != enteredName!
                    {
                        ConfigStore.removeScannedService(self.serviceName!)
                    }
                }
                else
                {
                    // new entry
                    ConfigStore.addScannedName(enteredName!, doNotDisplayWithoutName: doNotDisplayDevicesWithoutName)
                }
                self.navigationController?.popViewControllerAnimated(true)
            }
            else
            {
                self.presentViewController(UIAlertController.alertOnErrorWithMessage("Need to enter a name!"), animated:true, completion:nil)
            }
        }
    }
    
}

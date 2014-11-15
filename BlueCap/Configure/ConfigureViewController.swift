//
//  ConfigureViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class ConfigureViewController : UITableViewController {
    
    @IBOutlet var scanModeLabel                     : UILabel!
    @IBOutlet var servicesLabel                     : UILabel!
    @IBOutlet var scanTimeoutLabel                  : UILabel!
    @IBOutlet var scanTimeoutEnabledLabel           : UILabel!
    @IBOutlet var peripheralReconnectionsLabel      : UILabel!
    @IBOutlet var peripheralConnectionTimeout       : UILabel!
    @IBOutlet var characteristicReadWriteTimeout    : UILabel!
    @IBOutlet var scanRegionsLabel                  : UILabel!
    @IBOutlet var scanRegionSwitchLabel             : UILabel!
    @IBOutlet var scanRegionSwitch                  : UISwitch!
    @IBOutlet var scanTimeoutSwitch                 : UISwitch!
    @IBOutlet var notifySwitch                      : UISwitch!
    
    var scanMode = "None"
    
    struct MainStroryboard {
        static let configureScanServicesSegue   = "ConfigureScanServices"
        static let configureScanNamesSegue      = "ConfigureScanNames"
        static let configureScanRegionsSegue    = "ConfigureScanRegions"
        static let configureScanModeSegue       = "ConfigureScanMode"
        static let configureScanTimeoutSegue    = "ConfigureScanTimeout"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.notifySwitch.on = Notify.getEnabled()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.scanMode = ConfigStore.getScanMode()
        self.scanModeLabel.text = self.scanMode
        self.scanTimeoutSwitch.on = ConfigStore.getScanTimeoutEnabled()
        self.scanTimeoutLabel.text = "\(ConfigStore.getScanTimeout())s"
        self.peripheralReconnectionsLabel.text = "\(ConfigStore.getMaximumReconnections())"
        self.peripheralConnectionTimeout.text = "\(ConfigStore.getPeripheralConnectionTimeout())s"
        self.characteristicReadWriteTimeout.text = "\(ConfigStore.getCharacteristicReadWriteTimeout())s"
        self.configUI()
        self.navigationItem.title = "Configure"
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        if let identifier = identifier {
            switch(identifier) {
            case MainStroryboard.configureScanModeSegue:
                return true
            case MainStroryboard.configureScanRegionsSegue:
                return  !RegionScannerator.sharedInstance().isScanning && !CentralManager.sharedInstance().isScanning
            case MainStroryboard.configureScanServicesSegue:
                return true
            case MainStroryboard.configureScanNamesSegue:
                return true
            default:
                return true
            }
        } else {
            return false
        }
    }
    
    @IBAction func toggleScanRegion(sender:AnyObject) {
        ConfigStore.setRegionScanEnabled(!ConfigStore.getRegionScanEnabled())
        self.configUI()
    }
    
    @IBAction func toggleScanTimeout(sender:AnyObject) {
        ConfigStore.setScanTimeoutEnabled(!ConfigStore.getScanTimeoutEnabled())
    }
    
    @IBAction func toggelNotification(sender:AnyObject) {
        Notify.setEnable(enabled:self.notifySwitch.on)
    }
 
    func configUI() {
        if  CentralManager.sharedInstance().isScanning {
            self.scanRegionsLabel.textColor = UIColor.lightGrayColor()
            self.scanRegionSwitchLabel.textColor = UIColor.lightGrayColor()
            self.scanRegionSwitch.enabled = false
            self.scanTimeoutSwitch.enabled = false
            self.scanTimeoutEnabledLabel.textColor = UIColor.lightGrayColor()
        } else {
            self.scanRegionSwitch.enabled = true
            self.scanRegionSwitchLabel.textColor = UIColor.blackColor()
            self.scanRegionsLabel.textColor = UIColor.blackColor()
            self.scanTimeoutSwitch.enabled = true
            self.scanTimeoutEnabledLabel.textColor = UIColor.blackColor()
        }
        self.scanTimeoutSwitch.on = ConfigStore.getScanTimeoutEnabled()
        self.scanRegionSwitch.on = ConfigStore.getRegionScanEnabled()
    }

}

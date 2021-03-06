//
//  PeripheralsViewController.swift
//  BlueCapUI
//
//  Created by Troy Stribling on 6/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlueCapKit

class PeripheralsViewController : UITableViewController {
    
    var stopScanBarButtonItem   : UIBarButtonItem!
    var startScanBarButtonItem  : UIBarButtonItem!
    
    struct MainStoryboard {
        static let peripheralCell   = "PeripheralCell"
        static let peripheralSegue  = "Peripheral"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Stop, target:self, action:"toggleScan:")
        self.startScanBarButtonItem = UIBarButtonItem(title:"Scan", style:UIBarButtonItemStyle.Bordered, target:self, action:"toggleScan:")
        self.styleUIBarButton(self.startScanBarButtonItem)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.setScanButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralSegue {
            if let selectedIndex = self.tableView.indexPathForCell(sender as UITableViewCell) {
                let viewController = segue.destinationViewController as PeripheralViewController
                viewController.peripheral = CentralManager.sharedInstance().peripherals[selectedIndex.row]
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        var perform = false
        if let identifier = identifier {
            if identifier == MainStoryboard.peripheralSegue {
                if let selectedIndex = self.tableView.indexPathForCell(sender as UITableViewCell) {
                    let peripheral = CentralManager.sharedInstance().peripherals[selectedIndex.row]
                    perform = (peripheral.state == .Connected)
                }
            }
        }
        return perform
    }
    
    // actions
    func toggleScan(sender:AnyObject) {
        if BeaconManager.sharedInstance().isMonitoring() == false {
            let central = CentralManager.sharedInstance()
            if (central.isScanning) {
                if ConfigStore.getRegionScanEnabled() {
                    self.stopMonitoringRegions()
                    RegionScannerator.sharedInstance().stopScanning()
                } else if  ConfigStore.getScanTimeoutEnabled() {
                    TimedScannerator.sharedInstance().stopScanning()
                } else {
                    central.stopScanning()
                }
                self.setScanButton()
                central.disconnectAllPeripherals()
                central.removeAllPeripherals()
                self.updateWhenActive()
            } else {
                self.powerOn()
            }
        } else {
            self.presentViewController(UIAlertController.alertWithMessage("iBeacon monitoring is active. Cannot scan and monitor iBeacons simutaneously. Stop iBeacon monitoring to start scan"), animated:true, completion:nil)
        }
    }
    
    // utils
    func didResignActive() {
        Logger.debug("PeripheralsViewController#didResignActive")
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralsViewController#didBecomeActive")
        self.tableView.reloadData()
    }
    
    func setScanButton() {
        if CentralManager.sharedInstance().isScanning || RegionScannerator.sharedInstance().isScanning || TimedScannerator.sharedInstance().isScanning {
            self.navigationItem.setLeftBarButtonItem(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setLeftBarButtonItem(self.startScanBarButtonItem, animated:false)
        }
    }
    
    func powerOn() {
        CentralManager.sharedInstance().powerOn(){
            Logger.debug("powerOn Callback")
            self.startScan()
            self.setScanButton()
        }
    }
    
    func connect(peripheral:Peripheral) {
        peripheral.connect(connectorator:Connectorator(){(connectorator) in
            connectorator.timeoutRetries = ConfigStore.getMaximumReconnections()
            connectorator.connectionTimeout = Double(ConfigStore.getPeripheralConnectionTimeout())
            connectorator.characteristicTimeout = Double(ConfigStore.getCharacteristicReadWriteTimeout())
            connectorator.disconnect = {(periphearl) in
                Logger.debug("PeripheralsViewController#disconnect")
                Notify.withMessage("Disconnected peripheral: '\(peripheral.name)'")
                peripheral.reconnect()
                NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                self.updateWhenActive()
            }
            connectorator.connect = {(peipheral) in
                Logger.debug("PeripheralsViewController#connect")
                Notify.withMessage("Connected peripheral: '\(peripheral.name)'")
                self.updateWhenActive()
            }
            connectorator.timeout = {(peripheral) in
                Logger.debug("PeripheralsViewController#timeout: '\(peripheral.name)'")
                NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                peripheral.reconnect()
                self.updateWhenActive()
            }
            connectorator.forceDisconnect = {(peripheral) in
                Logger.debug("PeripheralsViewController#onForcedDisconnect")
                Notify.withMessage("Force disconnection of: '\(peripheral.name)'")
                NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                self.updateWhenActive()
            }
            connectorator.giveUp = {(peripheral) in
                Logger.debug("PeripheralsViewController#giveUp: '\(peripheral.name)'")
                peripheral.terminate()
                self.updateWhenActive()
            }
        })
    }
    
    func startScan() {
        let scanMode = ConfigStore.getScanMode()
        let afterPeripheralDiscovered = {(peripheral:Peripheral, rssi:Int) -> () in
            Notify.withMessage("Discovered peripheral '\(peripheral.name)'")
            self.connect(peripheral)
            self.updateWhenActive()
        }
        let afterTimeout = {
            self.setScanButton()
        }
        // Region Scan Enabled
        if ConfigStore.getRegionScanEnabled() {
            switch scanMode {
                // Region Promiscuous Scan Enabled
            case "Promiscuous" :
                // Region Promiscuous Scan with Timeout Enabled
                if ConfigStore.getScanTimeoutEnabled() {
                    RegionScannerator.sharedInstance().startScanning(Double(ConfigStore.getScanTimeout()), afterPeripheralDiscovered:afterPeripheralDiscovered, afterTimeout:afterTimeout)
                } else {
                    RegionScannerator.sharedInstance().startScanning(afterPeripheralDiscovered)
                }
                self.startMonitoringRegions()
                break
                // Region Service Scan Enabled
            case "Service" :
                let scannedServices = ConfigStore.getScannedServiceUUIDs()
                if scannedServices.isEmpty {
                    self.presentViewController(UIAlertController.alertWithMessage("No scan services configured"), animated:true, completion:nil)
                } else {
                    // Region Service Scan with Timeout Enabled
                    if ConfigStore.getScanTimeoutEnabled() {
                        RegionScannerator.sharedInstance().startScanningForServiceUUIDs(Double(ConfigStore.getScanTimeout()), uuids:scannedServices,
                            afterPeripheralDiscoveredCallback:afterPeripheralDiscovered, afterTimeout:afterTimeout)
                    } else {
                        RegionScannerator.sharedInstance().startScanningForServiceUUIDs(scannedServices, afterPeripheralDiscovered:afterPeripheralDiscovered)
                    }
                    self.startMonitoringRegions()
                }
                break
            default:
                Logger.debug("Scan Mode :'\(scanMode)' invalid")
                break
            }
        } else {
            // Promiscuous Scan Enabled
            switch scanMode {
            case "Promiscuous" :
                // Promiscuous Scan with Timeout Enabled
                if ConfigStore.getScanTimeoutEnabled() {
                    TimedScannerator.sharedInstance().startScanning(Double(ConfigStore.getScanTimeout()), afterPeripheralDiscovered:afterPeripheralDiscovered, afterTimeout:afterTimeout)
                } else {
                    CentralManager.sharedInstance().startScanning(afterPeripheralDiscovered)
                }
                break
            case "Service" :
                let scannedServices = ConfigStore.getScannedServiceUUIDs()
                if scannedServices.isEmpty {
                    self.presentViewController(UIAlertController.alertWithMessage("No scan services configured"), animated:true, completion:nil)
                } else {
                    // Service Scan with Timeout Enabled
                    if ConfigStore.getScanTimeoutEnabled() {
                        TimedScannerator.sharedInstance().startScanningForServiceUUIDs(Double(ConfigStore.getScanTimeout()), uuids:scannedServices,
                            afterPeripheralDiscoveredCallback:afterPeripheralDiscovered, afterTimeout:afterTimeout)
                    } else {
                        CentralManager.sharedInstance().startScanningForServiceUUIDs(scannedServices, afterPeripheralDiscovered:afterPeripheralDiscovered)
                    }
                }
                break
            default:
                Logger.debug("Scan Mode :'\(scanMode)' invalid")
                break
            }
        }
    }
    
    func startMonitoringRegions() {
        RegionScannerator.sharedInstance().distanceFilter = 50.0
        for (name, location) in ConfigStore.getScanRegions() {
            RegionScannerator.sharedInstance().startMonitoringForRegion(CircularRegion(center:location, identifier:name) {(region) in
                region.exitRegion = {
                    Notify.withMessage("Exiting Region: \(name)")
                }
                region.enterRegion = {
                    Notify.withMessage("Entering Region: \(name)")
                }
                region.startMonitoringRegion = {
                    Logger.debug("Started Monitoring Region: \(name)")
                }
                })
        }
    }
    
    func stopMonitoringRegions() {
        for region in RegionScannerator.sharedInstance().regions {
            RegionScannerator.sharedInstance().stopMonitoringForRegion(region)
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return CentralManager.sharedInstance().peripherals.count
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralCell, forIndexPath: indexPath) as PeripheralCell
        let peripheral = CentralManager.sharedInstance().peripherals[indexPath.row]
        cell.nameLabel.text = peripheral.name
        cell.accessoryType = .None
        if peripheral.state == .Connected {
            cell.nameLabel.textColor = UIColor.blackColor()
            cell.rssiLabel.text = "\(peripheral.rssi)"
            cell.stateLabel.text = "Connected"
            cell.stateLabel.textColor = UIColor(red:0.1, green:0.7, blue:0.1, alpha:0.5)
        } else {
            cell.nameLabel.textColor = UIColor.lightGrayColor()
            cell.rssiLabel.text = "\(0)"
            cell.stateLabel.text = "Disconnected"
            cell.stateLabel.textColor = UIColor.lightGrayColor()
        }
        return cell
    }
    

}
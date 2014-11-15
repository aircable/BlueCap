//
//  ConfigureScanNamesViewController.swift
//  BlueCap
//
//  Created by chris clogg on 2014-11-14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class ConfigureScanNamesViewController : UITableViewController {
    
    struct MainStoryboard {
        static let configureScanNamesCell               = "ConfigureScanNamesCell"
        static let configureAddScanNameSegue            = "ConfigureAddScanName"
        static let configureEditScanNameSegue           = "ConfigureEditScanName"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.title = "Scanned Names"
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject?) {
        if segue.identifier == MainStoryboard.configureAddScanNameSegue {
        } else if segue.identifier == MainStoryboard.configureEditScanNameSegue {
            if let selectedIndexPath = self.tableView.indexPathForCell(sender as UITableViewCell) {
                let names = ConfigStore.getScannedNamesNames()
                let viewController = segue.destinationViewController as ConfigureScanNameViewController
                viewController.serviceName = names[selectedIndexPath.row]
            }
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return ConfigStore.getScannedNames().count
    }
    
    override func tableView(tableView:UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let names = ConfigStore.getScannedNamesNames()
            ConfigStore.removeScannedName(names[indexPath.row])
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimation.Fade)
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.configureScanNamesCell, forIndexPath: indexPath) as NameUUIDCell
        let names = ConfigStore.getScannedNamesNames()
        if let doNotDisplayWithoutName = ConfigStore.getScannedNameBool(names[indexPath.row]) {
            if doNotDisplayWithoutName {
                cell.uuidLabel.text = "Do not display devices without a name."
            }
            else {
                cell.uuidLabel.text = "Do display devices without a name."
            }
        } else {
            cell.uuidLabel.text = ""
        }
        cell.nameLabel.text = names[indexPath.row]
        return cell
    }
    
    // UITableViewDelegate
    
}
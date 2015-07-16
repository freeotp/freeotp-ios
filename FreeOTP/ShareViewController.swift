//
// FreeOTP
//
// Authors: Nathaniel McCallum <npmccallum@redhat.com>
//
// Copyright (C) 2015  Nathaniel McCallum, Red Hat
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import CoreBluetooth
import Foundation
import UIKit

class ShareViewController : UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let SERVICE = CBUUID(string: "B670003C-0079-465C-9BA7-6C0539CCD67F")
    private let CHARACT = CBUUID(string: "F4186B06-D796-4327-AF39-AC22C50BDCA8")

    private class Remote {
        let peripheral: CBPeripheral
        var characteristic: CBCharacteristic?

        init(_ p: CBPeripheral, _ c: CBCharacteristic? = nil) {
            peripheral = p
            characteristic = c
        }
    }

    private var remotes = Array<Remote>()
    private var manager: CBCentralManager!

    var token: Token!

    private func finish() {
        if let nc = navigationController {
            nc.popViewControllerAnimated(true)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }

    private func remove(peripheral: CBPeripheral) {
        for i in 0..<remotes.count {
            if remotes[i].peripheral == peripheral {
                remotes.removeAtIndex(i)
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 1)], withRowAnimation: .Fade)
                break
            }
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return remotes.count > 0 ? 2 : 1
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Local"

        case 1:
            return "Bluetooth"

        default:
            return nil
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1

        case 1:
            return remotes.count

        default:
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("shareRow")!
        let lbl = cell.viewWithTag(1) as! UILabel
        let act = cell.viewWithTag(2) as! UIActivityIndicatorView

        switch indexPath.section {
        case 0:
            lbl.text = "Copy to Clipboard"
            cell.userInteractionEnabled = true
            lbl.enabled = true

        case 1:
            let r = remotes[indexPath.row]
            cell.userInteractionEnabled = r.characteristic != nil
            act.alpha = r.characteristic != nil ? 0 : 1
            lbl.enabled = r.characteristic != nil
            lbl.text = r.peripheral.name

        default:
            break
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let codes = token.codes

        if codes.count > 0 {
            switch indexPath.section {
            case 0:
                UIPasteboard.generalPasteboard().string = codes[0].value
                finish()

            case 1:
                let r = remotes[indexPath.row]
                if let d = codes[0].value.dataUsingEncoding(NSUTF8StringEncoding) {
                    r.peripheral.writeValue(d, forCharacteristic: r.characteristic!, type: .WithResponse)
                }

            default:
                break
            }
        }
    }

    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case .PoweredOn: manager.scanForPeripheralsWithServices(nil, options: nil)
        default: manager.stopScan()
        }
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        // Skip devices we are connect(ed|ing) to
        for r in remotes {
            if r.peripheral == peripheral {
                return
            }
        }

        // Skip devices with no name
        if peripheral.name == nil {
            return
        }

        // Add the device to the UI
        remotes.append(Remote(peripheral))
        tableView.beginUpdates()
        if tableView.numberOfSections == 1 { tableView.insertSections(NSIndexSet(index: 1), withRowAnimation: .Fade) }
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: remotes.count - 1, inSection: 1)], withRowAnimation: UITableViewRowAnimation.Fade)
        tableView.endUpdates()

        // Attempt to connect to it
        central.connectPeripheral(peripheral, options: nil)
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([SERVICE])
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let svcs = peripheral.services {
            for svc in svcs {
                if svc.UUID == SERVICE {
                    peripheral.discoverCharacteristics([CHARACT], forService: svc)
                    return
                }
            }
        }

        remove(peripheral)
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let chrs = service.characteristics {
            for chr in chrs {
                if chr.UUID == CHARACT {
                    for i in 0..<remotes.count {
                        if remotes[i].peripheral == peripheral {
                            remotes[i].characteristic = chr

                            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 1)) {
                                UIView.animateWithDuration(0.3, animations: {
                                    (cell.viewWithTag(1)! as! UILabel).enabled = true
                                    cell.viewWithTag(2)!.alpha = 0.0
                                    cell.userInteractionEnabled = true
                                })
                            }

                            return
                        }
                    }
                }
            }
        }

        remove(peripheral)
    }

    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        finish()
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        remove(peripheral)
    }

    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        remove(peripheral)
    }

    override func viewDidLoad() {
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        manager.stopScan()
    }
}

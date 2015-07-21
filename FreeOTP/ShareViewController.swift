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

extension CBPeripheral {
    func findService(svc: CBUUID) -> CBService? {
        if let svcs = services {
            for s in svcs {
                if s.UUID == svc {
                    return s
                }
            }
        }

        return nil
    }
}

extension CBService {
    func findCharacteristic(chr: CBUUID) -> CBCharacteristic? {
        if let chrs = characteristics {
            for c in chrs {
                if c.UUID == chr {
                    return c
                }
            }
        }

        return nil
    }
}

class ShareViewController : UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let SERVICE = CBUUID(string: "B670003C-0079-465C-9BA7-6C0539CCD67F")
    private let CHARACT = CBUUID(string: "F4186B06-D796-4327-AF39-AC22C50BDCA8")
    private var peripherals = [CBPeripheral]()
    private var manager: CBCentralManager!

    var token: Token!

    private func finish() {
        if let nc = navigationController {
            nc.popViewControllerAnimated(true)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }

    private func register(peripheral: CBPeripheral) {
        peripherals.append(peripheral)

        // Add the device to the UI
        tableView.beginUpdates()
        if tableView.numberOfSections == 1 { tableView.insertSections(NSIndexSet(index: 1), withRowAnimation: .Fade) }
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: peripherals.count - 1, inSection: 1)], withRowAnimation: UITableViewRowAnimation.Fade)
        tableView.endUpdates()
    }

    private func unregister(peripheral: CBPeripheral) {
        if let i = peripherals.indexOf(peripheral) {
            manager.cancelPeripheralConnection(peripherals.removeAtIndex(i))

            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 1)], withRowAnimation: .Fade)
            if i == 0 { tableView.deleteSections(NSIndexSet(index: 1), withRowAnimation: .Fade) }
            tableView.endUpdates()
        }
    }

    private func connect(peripheral: CBPeripheral) {
        if peripherals.contains(peripheral) {
            switch peripheral.state {
            case .Disconnecting: fallthrough
            case .Disconnected:
                manager.connectPeripheral(peripheral, options: nil)

            case .Connected:
                self.centralManager(manager, didConnectPeripheral: peripheral)

            case .Connecting:
                return
            }

            NSTimer.scheduledTimerWithTimeInterval(
                3,
                target: self,
                selector: "timeout:",
                userInfo: peripheral,
                repeats: false
            )
        }
    }

    func timeout(timer: NSTimer) {
        if let p = timer.userInfo as! CBPeripheral? {
            if p.findService(SERVICE)?.findCharacteristic(CHARACT) == nil {
                switch p.state {
                case .Connecting: fallthrough
                case .Connected:
                    manager.cancelPeripheralConnection(p)

                default: break
                }
            }
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return peripherals.count > 0 ? 2 : 1
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
            return peripherals.count

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
            let chr = peripherals[indexPath.row].findService(SERVICE)?.findCharacteristic(CHARACT)
            cell.userInteractionEnabled = chr != nil
            act.alpha = chr != nil ? 0 : 1
            lbl.enabled = chr != nil
            lbl.text = peripherals[indexPath.row].name

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
                if let c = peripherals[indexPath.row].findService(SERVICE)?.findCharacteristic(CHARACT) {
                    if let d = codes[0].value.dataUsingEncoding(NSUTF8StringEncoding) {
                        peripherals[indexPath.row].writeValue(d, forCharacteristic: c, type: .WithResponse)
                    }
                }

            default:
                break
            }
        }
    }

    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case .PoweredOn:
            for p in central.retrieveConnectedPeripheralsWithServices([SERVICE]) {
                register(p)
                connect(p)
            }

            central.scanForPeripheralsWithServices([SERVICE], options: nil)

        default:
            central.stopScan()
        }
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        if peripheral.name != nil {
            register(peripheral)
            connect(peripheral)
        }
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.delegate = self

        if let svc = peripheral.findService(SERVICE) {
            if let _ = svc.findCharacteristic(CHARACT) {
                self.peripheral(peripheral, didDiscoverCharacteristicsForService: svc, error: nil)
            } else {
                peripheral.discoverCharacteristics([CHARACT], forService: svc)
            }
        } else {
            peripheral.discoverServices(nil)
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let svc = peripheral.findService(SERVICE) {
            if let _ = svc.findCharacteristic(CHARACT) {
                self.peripheral(peripheral, didDiscoverCharacteristicsForService: svc, error: nil)
            } else {
                peripheral.discoverCharacteristics([CHARACT], forService: svc)
            }
        } else {
            switch peripheral.state {
            case .Connecting: fallthrough
            case .Connected:
                unregister(peripheral)

            default: break
            }
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let _ = service.findCharacteristic(CHARACT) {
            let i = peripherals.indexOf(peripheral)!
            let c = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 1))

            UIView.animateWithDuration(0.3, animations: {
                let l = c?.viewWithTag(1) as! UILabel?
                l?.enabled = true
                c?.viewWithTag(2)?.alpha = 0.0
                c?.userInteractionEnabled = true
            })

            return
        }

        switch peripheral.state {
        case .Connecting: fallthrough
        case .Connected:
            unregister(peripheral)

        default: break
        }
    }

    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        finish()
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        connect(peripheral)
    }

    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        connect(peripheral)
    }

    override func viewDidLoad() {
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        manager.stopScan()
        for p in peripherals.reverse() {
            unregister(p)
        }
    }
}

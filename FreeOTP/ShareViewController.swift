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
    func findService(_ svc: CBUUID) -> CBService? {
        if let svcs = services {
            for s in svcs {
                if s.uuid == svc {
                    return s
                }
            }
        }

        return nil
    }
}

extension CBService {
    func findCharacteristic(_ chr: CBUUID) -> CBCharacteristic? {
        if let chrs = characteristics {
            for c in chrs {
                if c.uuid == chr {
                    return c
                }
            }
        }

        return nil
    }
}

class ShareViewController : UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    fileprivate let SERVICE = CBUUID(string: "B670003C-0079-465C-9BA7-6C0539CCD67F")
    fileprivate let CHARACT = CBUUID(string: "F4186B06-D796-4327-AF39-AC22C50BDCA8")
    fileprivate var peripherals = [CBPeripheral]()
    fileprivate var manager: CBCentralManager!

    var token: Token!

    fileprivate func finish() {
        if let nc = navigationController {
            nc.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    fileprivate func register(_ peripheral: CBPeripheral) -> Bool {
        if peripherals.contains(peripheral) { return false }
        if peripheral.name == nil { return false }
        peripherals.append(peripheral)

        // Add the device to the UI
        tableView.beginUpdates()
        if tableView.numberOfSections == 1 { tableView.insertSections(IndexSet(integer: 1), with: .fade) }
        tableView.insertRows(at: [IndexPath(row: peripherals.count - 1, section: 1)], with: UITableViewRowAnimation.fade)
        tableView.endUpdates()
        return true
    }

    fileprivate func unregister(_ peripheral: CBPeripheral) {
        if let i = peripherals.index(of: peripheral) {
            manager.cancelPeripheralConnection(peripherals.remove(at: i))

            tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(row: i, section: 1)], with: .fade)
            if i == 0 { tableView.deleteSections(IndexSet(integer: 1), with: .fade) }
            tableView.endUpdates()
        }
    }

    fileprivate func connect(_ peripheral: CBPeripheral) {
        if peripherals.contains(peripheral) {
            switch peripheral.state {
            case .disconnecting: fallthrough
            case .disconnected:
                manager.connect(peripheral, options: nil)

            case .connected:
                self.centralManager(manager, didConnect: peripheral)

            case .connecting:
                return
            }

            Timer.scheduledTimer(
                timeInterval: 3,
                target: self,
                selector: #selector(ShareViewController.timeout(_:)),
                userInfo: peripheral,
                repeats: false
            )
        }
    }

    @objc func timeout(_ timer: Timer) {
        if let p = timer.userInfo as! CBPeripheral? {
            if p.findService(SERVICE)?.findCharacteristic(CHARACT) == nil {
                switch p.state {
                case .connecting: fallthrough
                case .connected:
                    manager.cancelPeripheralConnection(p)

                default: break
                }
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return peripherals.count > 0 ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Local"

        case 1:
            return "Bluetooth"

        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1

        case 1:
            return peripherals.count

        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "shareRow")!
        let lbl = cell.viewWithTag(1) as! UILabel
        let act = cell.viewWithTag(2) as! UIActivityIndicatorView

        switch indexPath.section {
        case 0:
            lbl.text = "Copy to Clipboard"
            cell.isUserInteractionEnabled = true
            lbl.isEnabled = true

        case 1:
            let chr = peripherals[indexPath.row].findService(SERVICE)?.findCharacteristic(CHARACT)
            cell.isUserInteractionEnabled = chr != nil
            act.alpha = chr != nil ? 0 : 1
            lbl.isEnabled = chr != nil
            lbl.text = peripherals[indexPath.row].name

        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let codes = token.codes

        if codes.count > 0 {
            switch indexPath.section {
            case 0:
                UIPasteboard.general.string = codes[0].value
                finish()

            case 1:
                if let c = peripherals[indexPath.row].findService(SERVICE)?.findCharacteristic(CHARACT) {
                    if let d = codes[0].value.data(using: String.Encoding.utf8) {
                        peripherals[indexPath.row].writeValue(d, for: c, type: .withResponse)
                    }
                }

            default:
                break
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            for p in central.retrieveConnectedPeripherals(withServices: [SERVICE]) {
                if register(p) {
                    connect(p)
                }
            }

            central.scanForPeripherals(withServices: [SERVICE], options: nil)

        default:
            central.stopScan()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if register(peripheral) {
            connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self

        if let svc = peripheral.findService(SERVICE) {
            if let _ = svc.findCharacteristic(CHARACT) {
                self.peripheral(peripheral, didDiscoverCharacteristicsFor: svc, error: nil)
            } else {
                peripheral.discoverCharacteristics([CHARACT], for: svc)
            }
        } else {
            peripheral.discoverServices(nil)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let svc = peripheral.findService(SERVICE) {
            if let _ = svc.findCharacteristic(CHARACT) {
                self.peripheral(peripheral, didDiscoverCharacteristicsFor: svc, error: nil)
            } else {
                peripheral.discoverCharacteristics([CHARACT], for: svc)
            }
        } else {
            switch peripheral.state {
            case .connecting: fallthrough
            case .connected:
                unregister(peripheral)

            default: break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let _ = service.findCharacteristic(CHARACT) {
            let i = peripherals.index(of: peripheral)!
            let c = tableView.cellForRow(at: IndexPath(row: i, section: 1))

            UIView.animate(withDuration: 0.3, animations: {
                let l = c?.viewWithTag(1) as! UILabel?
                l?.isEnabled = true
                c?.viewWithTag(2)?.alpha = 0.0
                c?.isUserInteractionEnabled = true
            })

            return
        }

        switch peripheral.state {
        case .connecting: fallthrough
        case .connected:
            unregister(peripheral)

        default: break
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        finish()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connect(peripheral)
    }

    override func viewDidLoad() {
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        manager.stopScan()
        for p in peripherals.reversed() {
            unregister(p)
        }
    }
}

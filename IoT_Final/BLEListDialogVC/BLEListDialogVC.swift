//
//  BLEListDialogVC.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/2.
//

import UIKit
import CoreBluetooth

@objc protocol BLEListDialogVCDelegate {
    func choosePeripheral(peripheral: CBPeripheral, name: String)
}

class BLEListDialogVC: BasicVC {
    @IBOutlet var view_background: UIView!
    @IBOutlet var tableView: UITableView!
    
    private var peripheralList: [CBPeripheral] = [CBPeripheral]() { didSet { self.tableView.reloadData() }}
    private var peripheralsName: [String] = [String]()
    private var peripheralsRSSI: [Int] = [Int]()
    
    weak var delegate: BLEListDialogVCDelegate?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "BLEListTableViewCell", bundle: nil), forCellReuseIdentifier: "BLECell")
        
        view_background.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(leave)))
    }
    
    @objc private func leave() {
        dialogDismiss()
    }
}

extension BLEListDialogVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BLECell") as? BLEListTableViewCell else { return BLEListTableViewCell() }
        cell.setCell(name: peripheralsName[indexPath.row], rssi: peripheralsRSSI[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dialogDismiss()
        delegate?.choosePeripheral(peripheral: peripheralList[indexPath.row], name: peripheralsName[indexPath.row])
    }
}

extension BLEListDialogVC {
    override func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !peripheralList.contains(peripheral), let name = peripheral.name {
            peripheralList.append(peripheral)
            peripheralsName.append(name)
            peripheralsRSSI.append(Int(truncating: RSSI))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let index = peripheralList.firstIndex(of: peripheral) {
            peripheralList.remove(at: index)
            peripheralsName.remove(at: index)
            peripheralsRSSI.remove(at: index)
        }
    }
}


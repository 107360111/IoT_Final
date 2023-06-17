//
//  PeriphralVC.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/13.
//

import UIKit
import CoreBluetooth
import CoreLocation

class PeriphralVC: UIViewController, CBPeripheralManagerDelegate, CLLocationManagerDelegate {
    @IBOutlet var textView: UITextView!

    private var peripheralManager: CBPeripheralManager!
    private var gpsCharacteristic: CBMutableCharacteristic!
    private var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        textView.isEditable = false
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
   
    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            setupServices()
            
            let advertisementData = [CBAdvertisementDataLocalNameKey: "GPS BLE"]
            peripheralManager.startAdvertising(advertisementData)
        } else {
            print("Bluetooth is not powered on")
        }
    }
    
    private func setupServices() {
        let gpsCharacteristicUUID = CBUUID(string: "00001800-0000-1000-8000-00805F9B34FB")
        let gpsCharacteristicProperties: CBCharacteristicProperties = [.read, .write, .notify]
        let gpsCharacteristicPermissions: CBAttributePermissions = [.readable, .writeable]
        gpsCharacteristic = CBMutableCharacteristic(type: gpsCharacteristicUUID, properties: gpsCharacteristicProperties, value: nil, permissions: gpsCharacteristicPermissions)
        
        let serviceUUID = CBUUID(string: "00002A00-0000-1000-8000-00805F9B34FB")
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [gpsCharacteristic]
        
        peripheralManager.add(service)
        
        startUpdatingLocation()
    }
    
    private func startUpdatingLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
    }
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if let location = locations.last {
                guard self != nil, let lat = self?.changeCoor(coor: location.coordinate.latitude), let lng = self?.changeCoor(coor: location.coordinate.longitude) else { return }
                self?.sendGPSInfoToCentral(info: GPSModel(latitude: lat, longitude: lng))
            }
        }
    }
    
    private func changeCoor(coor: CLLocationDegrees) -> CLLocationDegrees {
        let format = "%.8f"
        let roundedCoor = String(format: format, coor)
        return Double(roundedCoor) ?? 0.0
    }
    
    private func sendGPSInfoToCentral(info: GPSModel) {
        guard let data = try? JSONEncoder().encode(info), let gpsChara = gpsCharacteristic else { return }
        
        peripheralManager.updateValue(data, for: gpsChara, onSubscribedCentrals: nil)
        
        textView.text = textView.text.appending("經度: \(info.longitude)\n緯度: \(info.latitude)\n\n")
        textView.scrollRangeToVisible(NSRange(location: textView.text.count - 1, length: 1))
    }
    
    internal func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic == gpsCharacteristic {
                if let value = request.value, let receivedData = try? JSONDecoder().decode(CallModel.self, from: value) {
                    showWarningDialogVC(isCentral: false, isFindDevice: receivedData.findDevice, isOverDistance: receivedData.overDistance)
                    
                    peripheral.respond(to: request, withResult: .success)
                }
            }
        }
    }
}

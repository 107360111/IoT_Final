//
//  PeripheralManager.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/13.
//

import Foundation
import CoreBluetooth
import CoreLocation

class GPSModel: Codable {
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    
    init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

class CallModel: Codable {
    var name: String
    var overDistance: Bool
    var findDevice: Bool
    
    init(name: String, overDistance: Bool, findDevice: Bool) {
        self.name = name
        self.overDistance = overDistance
        self.findDevice = findDevice
    }
}

protocol PeripheralManagerDelegate: AnyObject {
    func sendMsg(sendMsg: String)
}

class PeripheralManager: NSObject, CBPeripheralManagerDelegate, CLLocationManagerDelegate {
    private var peripheralManager: CBPeripheralManager!
    private var gpsCharacteristic: CBMutableCharacteristic!
    private var locationManager: CLLocationManager!
    
    weak var delegate: PeripheralManagerDelegate?
    
    override init() {
        super.init()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            setupServices()
            
            let advertisementData = [CBAdvertisementDataLocalNameKey: "GPS BLE"]
            peripheralManager.startAdvertising(advertisementData)
        } else {
            print("Bluetooth is not powered on")
        }
    }
    
    func setupServices() {
        let gpsCharacteristicUUID = CBUUID(string: "00001800-0000-1000-8000-00805F9B34FB")
        let gpsCharacteristicProperties: CBCharacteristicProperties = [.read, .notify]
        let gpsCharacteristicPermissions: CBAttributePermissions = [.readable]
        gpsCharacteristic = CBMutableCharacteristic(type: gpsCharacteristicUUID, properties: gpsCharacteristicProperties, value: nil, permissions: gpsCharacteristicPermissions)
        
        let serviceUUID = CBUUID(string: "00002A00-0000-1000-8000-00805F9B34FB")
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [gpsCharacteristic]
        
        peripheralManager.add(service)
        
        startUpdatingLocation()
    }
    
    func startUpdatingLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            sendGPSInfoToCentral(info: GPSModel(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        }
    }
    
    func sendGPSInfoToCentral(info: GPSModel) {
        guard let data = try? JSONEncoder().encode(info), let gpsChara = gpsCharacteristic else { return }
        peripheralManager.updateValue(data, for: gpsChara, onSubscribedCentrals: nil)
        self.delegate?.sendMsg(sendMsg: "經度: \(info.longitude)，緯度: \(info.latitude)")
    }
}

//
//  PeriphralVC.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/13.
//

import UIKit
import AVFoundation
import AudioToolbox
import CoreBluetooth
import CoreLocation

import Lottie

class PeriphralVC: UIViewController, CBPeripheralManagerDelegate, CLLocationManagerDelegate {
    @IBOutlet var textView: UITextView!
    
    @IBOutlet var view_gif: UIView!
    
    @IBOutlet var constraint_view_width: NSLayoutConstraint!
    
    private var peripheralManager: CBPeripheralManager!
    private var gpsCharacteristic: CBMutableCharacteristic!
    private var locationManager: CLLocationManager!
    
    private var audioPlayer: AVAudioPlayer?
    
    private var animationView = LottieAnimationView()
    
    private var connectCentralName: String?
    private var isTransmitting: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view_gif.isHidden = true
        constraint_view_width.constant = UIDevice.current.userInterfaceIdiom == .pad ? 500 : 200
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        textView.isEditable = false
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(cancelConnect), name: Notification.Name("removeApp"), object: nil)
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
        if isTransmitting {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if let location = locations.last {
                    guard self != nil, let lat = self?.changeCoor(coor: location.coordinate.latitude), let lng = self?.changeCoor(coor: location.coordinate.longitude) else { return }
                    self?.sendGPSInfoToCentral(info: GPSModel(latitude: lat, longitude: lng))
                }
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
        
        let originStr = NSMutableAttributedString(attributedString: textView.attributedText)
        
        let textStr = NSAttributedString(string: "經度: \(info.longitude)\n緯度: \(info.latitude)\n\n", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17.0)])
        
        originStr.append(textStr)
        
        textView.attributedText = originStr
        textView.scrollRangeToVisible(NSRange(location: textView.text.count - 1, length: 1))
    }
        
    internal func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic == gpsCharacteristic {
                if let value = request.value, let receivedData = try? JSONDecoder().decode(CallModel.self, from: value) {
                    showWarningDialogVC(isCentral: false, isFindDevice: receivedData.findDevice, isOverDistance: receivedData.overDistance)
                    playSound(isFindDevice: receivedData.findDevice)
                    
                    peripheral.respond(to: request, withResult: .success)
                    stopScanning(isStop: true)
                } else if let value = request.value, let receivedData = try? JSONDecoder().decode(ConnectModel.self, from: value) {
                    setGIFView(isConnect: receivedData.isConnct)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.view_gif.isHidden = true
                        self.animationView.removeFromSuperview()
                        self.textView.text = self.textView.text.appending("========     \(receivedData.isConnct ? "已連接" : "斷開連接")     ========\n\n")
                        peripheral.respond(to: request, withResult: .success)
                    }
                }
            }
        }
    }
    
    private func stopScanning(isStop: Bool) {
        isTransmitting = !isStop
        if isStop {
            locationManager.stopUpdatingLocation()
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func setGIFView(isConnect: Bool) {
        view_gif.isHidden = false
        animationView = LottieAnimationView(name: isConnect ? "connect" : "disconnect")
        animationView.frame = CGRect(x: 0, y: 0, width: constraint_view_width.constant, height: constraint_view_width.constant)
        animationView.contentMode = .scaleAspectFit
                
        animationView.loopMode = .playOnce
        animationView.animationSpeed = 0.8
        
        view_gif.addSubview(animationView)
        
        animationView.play()
    }
    
    private func playSound(isFindDevice: Bool) {
        guard let url = Bundle.main.url(forResource: isFindDevice ? "ding_dong" : "warning", withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.rate = 0.75
            audioPlayer?.play()
        } catch {
            print("無法播放鈴聲:\(error.localizedDescription)")
        }
    }
        
    @objc private func cancelConnect() {
        guard let data = try? JSONEncoder().encode(ConnectModel(isConnct: false)), let gpsChara = gpsCharacteristic else { return }
        peripheralManager.updateValue(data, for: gpsChara, onSubscribedCentrals: nil)
    }
}

extension PeriphralVC: WarningDialogVCDelegate {
    func leave() {
        audioPlayer?.stop()
        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
        stopScanning(isStop: false)
    }
}

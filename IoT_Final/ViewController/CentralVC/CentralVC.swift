//
//  CentralVC.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/13.
//

import UIKit
import CoreBluetooth
import CoreLocation

import Lottie
import RadarKit
import Turf
import Toast_Swift

class CentralVC: UIViewController {
    @IBOutlet var view_button_show: UIStackView!
    @IBOutlet var view_quit: UIView!
    @IBOutlet var view_call: UIView!
    
    @IBOutlet var view_title: UIView!
    @IBOutlet var label_title: UILabel!
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var radarView: CustomRadarView!
    @IBOutlet var view_mainPoint: UIView!
    @IBOutlet var view_targetPoint: UIView!

    /// 正數往東、負數往西，Max = 180
    @IBOutlet var constraint_target_lng: NSLayoutConstraint!
    /// 正數往南、負數往北，Max = 180
    @IBOutlet var constraint_target_lat: NSLayoutConstraint!
    
    @IBOutlet var view_loading_show: UIView!
    @IBOutlet var view_loading: UIView!
    @IBOutlet var constraint_loading: NSLayoutConstraint!
    
    private var centralManager: CBCentralManager?
    private var locationManager: CLLocationManager!
    
    private var peripheralManager: CBPeripheralManager!
    private var characteristic: CBCharacteristic!
    
    private var peripheralsList = [CBPeripheral]() { didSet { self.tableView.reloadData() }}
    private var peripheralsName = [String]()
    private var peripheralsRSSI = [Int]()
    private var getCoorData = false
    
    private var timer: Timer?
    
    // 上限範圍，單位cm，討論過後決定變成比例尺的概念(固定)
    private var tempLimitMeter: Int = 2000
    private var tempPeripheral: CBPeripheral?
    private var currentCoor: GPSModel?
    private var targetCoor: GPSModel?
    
    private var tempDialog: CallModel?
    private var tempisAuto: Bool = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeShow(connected: false)
        
        view_quit.layer.cornerRadius = 4
        view_quit.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(quitconnected)))
        
        view_call.layer.borderColor = CGColor(red: 196, green: 196, blue: 196, alpha: 1)
        view_call.layer.cornerRadius = 4
        view_call.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(findDevice)))
        
        view_title.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(overLimit)))
        
        constraint_loading.constant = UIDevice.current.userInterfaceIdiom == .pad ? 500 : 200
        GIFInit()
        registerInit()
        configureRadarView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
    }
    
    @objc private func quitconnected() {
        if let peripheral = tempPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
            centralManager?.scanForPeripherals(withServices: nil)
            changeShow(connected: false)
            getCoorData = false
        }
    }
    
    @objc private func findDevice() {
        /// 發送通知給連接裝置停止傳送資訊
        sendPeripheral(info: CallModel(overDistance: false, findDevice: true), withoutRes: false)
    }
    
    @objc private func overLimit() {
        /// 超出範圍跳視窗並停止接收資訊
        sendPeripheral(info: CallModel(overDistance: true, findDevice: false), withoutRes: true)
    }
    
    @objc private func getPeripheralRes() {
        if tempisAuto {
            if let info = tempDialog {
                showWarningDialogVC(isCentral: true, isFindDevice: info.findDevice, isOverDistance: info.overDistance)
            }
        } else {
            self.view.makeToast("資料已送出")
        }
    }
    
    private func GIFInit() {
        let animationView = LottieAnimationView(name: "bluetooth")
        animationView.frame = CGRect(x: 0, y: 0, width: constraint_loading.constant, height: constraint_loading.constant)
        animationView.contentMode = .scaleAspectFit
                
        animationView.loopMode = .loop
        animationView.animationSpeed = 0.8
        
        view_loading.addSubview(animationView)
        
        animationView.play()
    }
    
    private func registerInit() {
        tableView.register(UINib(nibName: "BLEListTableViewCell", bundle: nil), forCellReuseIdentifier: "BLEListCell")
        centralManager = CBCentralManager(delegate: self, queue: .main)
        
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
    
    private func configureRadarView() {
        radarView.diskRadius = 1.0
        radarView.numberOfCircles = 4
        radarView.paddingBetweenCircle = 36
        radarView.paddingBetweenItems = 20
        radarView.animationDuration = 1.8
        
        radarView.dotColor = .ringStroke.filterNil
        radarView.circleOnColor = UIColor.white
        radarView.circleOffColor = .ringStroke.filterNil
        radarView.isRotateRingAnimation = true
        
        addMainPoint(size: 50)
        addTargetPoint(size: 50)
    }
    
    private func addMainPoint(size: Int) {
        let mainPoint = LottieAnimationView(name: "location")
        
        mainPoint.frame = CGRect(x: 0, y: 0, width: size, height: size)
        mainPoint.contentMode = .scaleAspectFit
        
        mainPoint.loopMode = .loop
        mainPoint.animationSpeed = 1
        
        view_mainPoint.addSubview(mainPoint)
        mainPoint.play()
    }
    
    private func addTargetPoint(size: Int) {
        let targetPoint = LottieAnimationView(name: "targetPoint")
        
        targetPoint.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        targetPoint.contentMode = .scaleAspectFit
        
        targetPoint.loopMode = .loop
        targetPoint.animationSpeed = 1
        
        view_targetPoint.addSubview(targetPoint)
        targetPoint.play()
    }
    
    private func setTargetPoint(start: GPSModel, end: GPSModel) {
        let myLocation = CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude)
        
        let NS_coorDiff = myLocation.distance(to: CLLocationCoordinate2D(latitude: end.latitude, longitude: start.longitude))
        let EW_coorDiff = myLocation.distance(to: CLLocationCoordinate2D(latitude: start.latitude, longitude: end.longitude))
        
        let conLat = calculateDistance(meter: NS_coorDiff, isLat: true, isStartLarge: start.latitude > end.latitude)
        let conLng = calculateDistance(meter: EW_coorDiff, isLat: false, isStartLarge: start.longitude > end.longitude)
        
        constraint_target_lat.constant = conLat
        constraint_target_lng.constant = conLng
    }
    
    private func calculateDistance(meter: LocationDistance, isLat: Bool, isStartLarge: Bool) -> CGFloat {
        // 1.414 = 根號2
        let radarRadius: Int = Int(radarView.bounds.size.width / 2.828)
        if isLat {
            if isStartLarge {
                return -min(CGFloat(Int(Double(meter) * Double(radarRadius / (tempLimitMeter / 100)))), CGFloat(radarRadius))
            } else {
                return min(CGFloat(Int(Double(meter) * Double(radarRadius / (tempLimitMeter / 100)))), CGFloat(radarRadius))
            }
        } else {
            if isStartLarge {
                return min(CGFloat(Int(Double(meter) * Double(radarRadius / (tempLimitMeter / 100)))), CGFloat(radarRadius))
            } else {
                return -min(CGFloat(Int(Double(meter) * Double(radarRadius / (tempLimitMeter / 100)))), CGFloat(radarRadius))
            }
        }
    }
    
    private func changeShow(connected: Bool) {
        tableView.isHidden = connected
        view_button_show.isHidden = !connected
        radarView.isHidden = !connected
        label_title.text = connected ? "藍芽配對成功" : "請選擇欲連接藍芽裝置"
    }
    
    private func calculateDistance(start: GPSModel, end: GPSModel) {
        let myLocation = CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude)
        let targetLocation = CLLocationCoordinate2D(latitude: end.latitude, longitude: end.longitude)
        self.changeLabel(real_distance: getCoor(coor: myLocation.distance(to: targetLocation), decimalPlaces: 2))
    }
    
    private func getCoor(coor: Double, decimalPlaces: Int) -> Double {
        let format = "%.\(decimalPlaces)f"
        let roundedCoor = String(format: format, coor)
        return Double(roundedCoor) ?? 0.0
    }
    
    private func changeLabel(real_distance: Double) {
        let distance = min(real_distance, 20)
        let arrivedLimit: Bool = real_distance > 20 * 1.2
        
        let distanceStr = NSMutableAttributedString()
        distanceStr.append(NSAttributedString(string: "目標裝置："))
        let disStr = NSAttributedString(string: judgeLabelText(distance: distance), attributes: [NSAttributedString.Key.foregroundColor: arrivedLimit ? UIColor.red : UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: arrivedLimit ? 28.0 : 24.0)])
        distanceStr.append(disStr)
        
        self.label_title.attributedText = distanceStr
        
        if arrivedLimit {
            /// 超出範圍跳視窗並停止傳送資訊
            sendPeripheral(info: CallModel(name: ,overDistance: true, findDevice: false), withoutRes: false)
        }
    }
    
    private func judgeLabelText(distance: Double) -> String {
        switch distance {
        case 0..<8 :
            return "近距離"
        case 8..<15 :
            return "中距離"
        case 15..<20 :
            return "中遠距離"
        case 20..<24 :
            return "遠距離"
        default:
            return "超出偵測距離"
        }
    }
    
    private func sendPeripheral(info: CallModel, withoutRes: Bool) {
        /// 關閉掃描
        centralManager?.stopScan()
        
        tempDialog = info
        tempisAuto = withoutRes
        
        guard let data = try? JSONEncoder().encode(info) else { return }
        
        if let peripheral = tempPeripheral, let characteristic = characteristic {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
}

extension CentralVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BLEListCell") as? BLEListTableViewCell else { return BLEListTableViewCell() }
        cell.setCell(name: peripheralsName[indexPath.row], rssi: peripheralsRSSI[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tempPeripheral = peripheralsList[indexPath.row]
        centralManager?.connect(peripheralsList[indexPath.row], options: nil)
        tableView.deselectRow(at: indexPath, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.view_loading_show.isHidden = false
        }
    }
}

extension CentralVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentCoor = GPSModel(latitude: getCoor(coor: location.coordinate.latitude, decimalPlaces: 8), longitude: getCoor(coor: location.coordinate.longitude, decimalPlaces: 8))
        }
    }
}

extension CentralVC: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil)
        } else {
            central.stopScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !peripheralsList.contains(peripheral), let name = peripheral.name {
            peripheralsList.append(peripheral)
            peripheralsName.append(name)
            peripheralsRSSI.append(Int(truncating: RSSI))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        central.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("連線失敗:\(String(describing: error?.localizedDescription))")
        self.view.makeToast("連線失敗:\(String(describing: error?.localizedDescription))")
        self.view_loading.isHidden = true
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("因外部因素斷開連結了:\(String(describing: error?.localizedDescription))")
        self.view.makeToast("因外部因素斷開連結了:\(String(describing: error?.localizedDescription))")
        self.view_loading.isHidden = true
        
        changeShow(connected: false)
        getCoorData = false
    }
}

extension CentralVC: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("尋找 services 時 \(String(describing: peripheral.name)) 發生錯誤， \(String(describing: error?.localizedDescription))")
            self.view.makeToast("尋找 services 時 \(String(describing: peripheral.name)) 發生錯誤， \(String(describing: error?.localizedDescription))")
            self.view_loading.isHidden = true
            
            changeShow(connected: false)
            getCoorData = false
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("搜尋特徵值出錯：\(error.localizedDescription)")
            self.view.makeToast("搜尋特徵值出錯：\(error.localizedDescription)")
            view_loading.isHidden = true
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == CBUUID(string: "00001800-0000-1000-8000-00805F9B34FB") {
                    self.characteristic = characteristic
                }
                
                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                }
                
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("寫入特徵值出錯：\(error.localizedDescription)")
            self.view.makeToast("寫入特徵值出錯：\(error.localizedDescription)")
            return
        }
        
        print("接收到來自發送端的訊息")
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(getPeripheralRes), userInfo: nil, repeats: false)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            if let receivedData = try? JSONDecoder().decode(GPSModel.self, from: value) {
                
                targetCoor = receivedData
                
                guard let start = currentCoor, let end = targetCoor else { return }
                if !getCoorData {
                    view_loading_show.isHidden = true
                    changeShow(connected: true)
                    getCoorData = true
                }
                
                setTargetPoint(start: start, end: end)
                calculateDistance(start: start, end: end)
            } else if let receivedData = try? JSONDecoder().decode(CallModel.self, from: value) {
                
            } else {
                return
            }
        }
    }
}

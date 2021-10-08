//  BLEManager.swift
//
//  Created by WPHU on 2018/2/1.
//  Copyright © 2018年 MacPro@kawa. All rights reserved.
//

import UIKit
import CoreBluetooth

enum status {
    case none
    case centralManagerDidUpdateState
    case startScan
    case stopScan
    case startConnect
    case didConnect
    case ConnectOK
    case didDisconnect
    case PairingFailed
    case didFailToConnect
    case timeOut
}

class BLEManager :NSObject,CBCentralManagerDelegate,CBPeripheralDelegate{
    static var sharedInstance = BLEManager()
    
    private override init() {
        print("BLEManager Singleton initialized")
    }
    private var _centralManager :CBCentralManager!
    private var _isPowerOn = false
    
    //-------------------------------------------------------------
    /** add Listener 設監聽器 回傳事件 （可選）*/
    /** add status Listeners 設監聽器 狀態事件 */
    private var _statusListeners = [(status,CBPeripheral) ->()]()
    public func addStatusListener(Listener:@escaping (status,CBPeripheral) ->()){
        _statusListeners.append(Listener)
    }
    private func sendStatusListener(status:status,peripheral:CBPeripheral){
        if(_statusListeners.count <= 0){
            return
        }
        for sl in _statusListeners {
            sl(status,peripheral)
        }
    }
    /** add notify Listeners 設監聽器 回傳事件 */
    private var _notifyListeners = [(String,CBPeripheral) ->()]()
    public func addNotifyListener(Listener:@escaping (String,CBPeripheral) ->()){
        _notifyListeners.append(Listener)
    }
    private func sendNotifyListener(message:String,peripheral:CBPeripheral){
        if(_notifyListeners.count <= 0){
            return
        }
        for nl in _notifyListeners {
            nl(message,peripheral)
        }
    }
    
    private var _notifyHexListener:((UInt8,Int,[UInt8],Any) ->())?
    public func setNotifyHexListener(Listener:@escaping (UInt8,Int,[UInt8],Any) ->()){
        _notifyHexListener = Listener
    }
    
    /** add write Listeners 設監聽器 寫入事件 */
    private var _writeListeners = [(Bool,CBPeripheral) ->()]()
    public func addWriteListener(Listener:@escaping (Bool,CBPeripheral) ->()){
        _writeListeners.append(Listener)
    }
    private func sendWriteListener(isSuccess:Bool,peripheral:CBPeripheral){
        if(_writeListeners.count <= 0){
            return
        }
        for wl in _writeListeners {
            wl(isSuccess,peripheral)
        }
    }
    //-------------------------------------------------------------
    
    private var _BLEData:BLEData?
    
    public func setUp(){
        print("BLEManager setUp")
        _centralManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    /**藍芽啟動*/
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("BLEManager centralManagerDidUpdateState")
        ///判斷藍牙是否開啟
        guard central.state == .poweredOn else {
            _isPowerOn = false
            return
        }
        _isPowerOn = true
    }
    /*連線開始**/
    public func startConnect(BLEData:BLEData){
        print("BLEManager startConnect")
        if(_isPowerOn == false){return}
        if(BLEData.peripheral == nil){return}
        _BLEData = BLEData
        _BLEData!.peripheral?.delegate = self
        _centralManager.connect(BLEData.peripheral!, options: nil)
    }
    /*取消連線**/
    public func cancelConnect(BLEData:BLEData){
        print("BLEManager cancelConnect")
        
        if(_isPowerOn == false){return}
        if(BLEData.peripheral == nil){return}
        _centralManager.cancelPeripheralConnection((BLEData.peripheral!))
    }
    
    /**連線成功*/
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("BLEManager \(String(describing: peripheral.name))   didConnect")
        
        self.sendStatusListener(status: .didConnect,peripheral: peripheral)
       
        peripheral.delegate = self
        ///查找Services
        peripheral.discoverServices(nil)
    }
    
    /**連線失敗*/
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("BLEManager didFailToConnect")
        
        self.sendStatusListener(status: .didFailToConnect,peripheral: peripheral)
    }
    
    /**與現有連線中斷*/
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("BLEManager ConnectOut didDisconnectPeripheral")
        
        self.sendStatusListener(status: .didDisconnect,peripheral: peripheral)
    }

    private let _dispatchGroup = DispatchGroup() // instance-level definition //新增一個任務計數器
    /**取得Services*/
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("BLEManager didDiscoverServices")
        
        guard error == nil else {
            print("BLEManager didDiscoverServices error:\(error!.localizedDescription)")
            
            self.sendStatusListener(status: .PairingFailed,peripheral: peripheral)
            return
        }
        
        for _ in peripheral.services!{
            _dispatchGroup.enter()//新增計數數量
            
        }
        
        _dispatchGroup.notify(queue: .main) {
            print("ALL didDiscoverCharacteristics Done")
            self.sendStatusListener(status: .ConnectOK,peripheral: peripheral)
        }
        
        for service in peripheral.services!{
            ///查找Characteristics
            _BLEData!.servicesUUID.append(service.uuid)
            print("BLEManager service.uuid:\(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
    }
    /**取得特徵Characteristics*/
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("BLEManager didDiscoverCharacteristics [service:\(service.uuid)]")
        
        guard error == nil else {
            print("BLEManager didDiscoverServices error:\(error!.localizedDescription)")
            return
        }
        
            ///入存Data
            let sd = serviceData()
            sd.service = service
            sd.serviceUUID = service.uuid
            _BLEData!.services.append(sd)
            
            for characteristic in service.characteristics!{
        
                var cd = CharacteristicData()
                cd.Characteristic = characteristic
                cd.CharacteristicUUID = characteristic.uuid
                sd.Characteristics.append(cd)///入存Data
                
                let uuid = characteristic.uuid.uuidString
                print("BLEManager characteristic.uuid:\(uuid)")
                //                var s :String = ""
                //                if(characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue != 0) {
                //                    s.append("．通知")
                //                }
                //                if(characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue != 0) {
                //                    s.append("．讀")
                //                }
                //                if(characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue != 0) {
                //                    s.append("．寫")
                //                }
                //                print(uuid + "    -" + s)
                
                //                if(service.characteristics?.count == index && serviceCount == 0){
                //                    print("Connect OK!!!!\(data.services[0].Characteristics.count)")
                //                    if(_statusListener != nil){
                //                        _statusListener!(.ConnectOK,peripheral)
                //                    }
                //                }
//                if(characteristic.uuid.uuidString == "1111"){
//                    self.readValueForCharacteristic(Peripheral: peripheral, Characteristic: characteristic)
//                }
        }
        
        _dispatchGroup.leave() //完成計數數量
    }
    
    ///-------------------------------------------------------------------------------------------------------------///
    ///-------------------------------------------------------------------------------------------------------------///
    public func readValueForCharacteristic(Peripheral:CBPeripheral,Characteristic:CBCharacteristic){
        Peripheral.readValue(for: Characteristic)
    }
    public func writeValueForCharacteristic(valueData:[UInt8],Peripheral:CBPeripheral,Characteristic:CBCharacteristic){
        let data = Data(bytes:valueData)
        Peripheral.writeValue(data, for: Characteristic, type: .withResponse)
        let str: String? = String(data: data, encoding: .utf8)
        print("writeValue:\(String(describing: str))")
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if(error == nil){
            print("didWriteValueFor  Success")
            sendWriteListener(isSuccess: true, peripheral: peripheral)
            return
        }
        print("didWriteValueFor  erroe:\(error!)")
        sendWriteListener(isSuccess: false, peripheral: peripheral)
    }
    public func setNotifyForCharacteristic(Peripheral:CBPeripheral,Characteristic:CBCharacteristic,Enabled:Bool){
        Peripheral.setNotifyValue(Enabled, for: Characteristic)
    }

    
    static var indexTest = 0
    /** BLE通知回傳接收 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print(error!.localizedDescription)
            return
        }
//        print("收到Notify0：\(characteristic.value![0]) ,UUID:\(characteristic.uuid.uuidString)")
        var resultStr = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
//        print("收到Notify：\(characteristic),UUID:\(characteristic.uuid.uuidString)")
        let count:Int = (characteristic.value?.count)!
        
        var hexString :[String] = []
        for i in (0..<count) {
            hexString.append(NSString(format:"%2X", characteristic.value![i]) as String )
        }
        print("收到Notify：\(hexString),[hex],UUID:\(characteristic.uuid.uuidString)")
        
        var hexArray :[UInt8] = []
        for i in (0..<count) {
            hexArray.append(characteristic.value![i])
        }
        

//        print("收到Notify：\(hexArray),[hex],UUID:\(characteristic.uuid.uuidString)")
//        print("收到Notify：\(hexStringArray),[hex],UUID:\(characteristic.uuid.uuidString)")
        print("收到Notify：\(resultStr)「resultStr」")
        //回送 第一種監聽 根據自己需求監聽哪總格式 (String)
        if(hexArray.count > 0){
            if(resultStr == nil){
                return
            }
            sendNotifyListener(message: resultStr! as String, peripheral: peripheral)
        }
        //回送 第二種監聽 根據自己需求監聽哪總格式 (HEX)
        if(_notifyHexListener != nil && hexArray.count > 1){
            let count = Int(hexArray[1])
            var value :[UInt8] = []
            for i in (2..<hexArray.count) {
                value.append(hexArray[i])
            }
            _notifyHexListener!(hexArray[0],count, value, characteristic)
        }
        
//        if(characteristic.uuid.uuidString == BluetoothLeAttributes.CHANGEON_DEVICE_NAME){
//            for data in _BLEDatas{
//                if(data.peripheral?.identifier.uuidString != peripheral.identifier.uuidString){
//                    continue
//                }
//                peripheral.delegate = self
//                data.peripheral = peripheral
//                if(_statusListener != nil){
//                    _statusListener!(.ConnectOK,peripheral)
//                }
//
//            }
//        }
//
    }
    //--------------------------------------------------------------------------------------------
    //MARK:Scan ble
    //--------------------------------------------------------------------------------------------
    private var _scanListener:((CBPeripheral,[String : Any]) ->())?
    private var _timer = Timer()
    private var _second :TimeInterval? = nil
    
    /**藍芽Device掃描*/ /**[ (CBPeripheral)  ]=這個東西     [  ->() ] =往外丟*/
    public func startScan(second:TimeInterval?,scanListener:@escaping (CBPeripheral,[String : Any]) ->()){
        
        self._second = second
        self._scanListener = scanListener //註冊監聽
        
        self._centralManager.scanForPeripherals(withServices: nil, options: nil)
//        let queue = DispatchQueue.global()///不同執行緒
//        self._BLEManager = CBCentralManager(delegate: self, queue: queue)///實體化BLE 並啟動
    }
    
    /**連線遇時*/
    @objc func timeOutStop() {
        print("timeOutStopScan")
        self._centralManager.stopScan()
    }
    
    /**掃描停止*/
    public func stopScan(){
        print("stopScan")
        self._centralManager.stopScan()
    }
    
    /**獲取(掃描)週邊設備資料callback*/
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        self._scanListener!(peripheral, advertisementData)
    }
    //--------------------------------------------------------------------------------------------
}

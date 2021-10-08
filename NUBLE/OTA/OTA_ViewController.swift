//
//  OTA_ViewController.swift
//  NUBLE
//
//  Created by WPHU on 2021/8/31.
//

import UIKit
import BLEFramework
import CoreBluetooth

class OTA_ViewController: UIViewController {

//    private var _BleData:BLEData? = nil //自己管？如果行不通再丟回去給main管吧
    private let _bms = BLEManager.sharedInstance
    private var _status:status = .none

    //用來檢查是否是執行ＯＴＡ結束後的斷線
    private var _isOTA_Over = false
    
    @IBOutlet weak var BleDeviceNameLabel: UILabel!
    @IBOutlet weak var BleStatusLabel: UILabel!
    @IBOutlet weak var ScanBleButton: UIButton!
    @IBOutlet weak var LogTextView: UITextView!
    @IBOutlet weak var StartOTAButton: UIButton!
    @IBOutlet weak var SelectBinButton: UIButton!
    @IBOutlet weak var LoadIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //設置監聽 [從哪個功能回來]
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectBLE(notification:)), name: NSNotification.Name("ConnectBLE") , object: nil)
        
        //OTA Button 初始不啟用
        self.ButtonController(isScanEnabled: true, isSelectEnabled: false,isOTAEnabled: false, isLoadIndicatorAnimating: false)
        
        _bms.addStatusListener { (status, peripheral) in
            
            if(ViewController._OTA_BleData?.peripheral != peripheral){ //真的有要提高效率再來分出一層做BLECollectionManager吧
                return
            }
            
            self._status = status
            
            self.UpdateView()
            
            if(status == .ConnectOK){
                //連線成功
                ViewController.bleFramework.peripheralInUse = peripheral
                
                ViewController.bleFramework.RegisterPeripheral(customized: true, to: peripheral);
                
                let c_indicate_uuid = ViewController._OTA_BleData?.getCharacteristicByUUID(UUID: BluetoothLeAttributes.NEW_FOTACHARACTERISTICUUID_WRITE_INDICATE)
                let c_notify_uuid = ViewController._OTA_BleData?.getCharacteristicByUUID(UUID: BluetoothLeAttributes.NEW_FOTACHARACTERISTICUUID_WRITENORESPONSE_NOTIFY)
                
                if(c_notify_uuid == nil){
                    self.ButtonController(isScanEnabled: true, isSelectEnabled: false, isOTAEnabled: false, isLoadIndicatorAnimating: false)
                    return
                }
                
                self.ButtonController(isScanEnabled: true, isSelectEnabled: true, isOTAEnabled: false, isLoadIndicatorAnimating: false)
                
                if(c_indicate_uuid != nil){
                    ViewController.bleFramework.fotaInUseWriteIndicate = c_indicate_uuid
                    ViewController.bleFramework.SetNotify(to:peripheral , characteristic: c_indicate_uuid!, enabled: true)
                    
                }
                
                if(c_notify_uuid != nil){
                    ViewController.bleFramework.fotaInUseWriteNotify = c_notify_uuid
                    ViewController.bleFramework.SetNotify(to: peripheral, characteristic: c_notify_uuid!, enabled: true)
                }
                
                if(self._isOTA_Over == true){
                    //檢查更新結果
                    self._isOTA_Over = false
                    self.checkVersion()
                    self.ButtonController(isScanEnabled: true, isSelectEnabled: true, isOTAEnabled: false, isLoadIndicatorAnimating: false)
                }
            }
            
            if(status == .didDisconnect){
                if(self._isOTA_Over == true){
                    
                    //重新連線
                    self._bms.startConnect(BLEData: ViewController._OTA_BleData!)
                    ViewController.bleFramework.peripheralInUse = ViewController._OTA_BleData!.peripheral!
                    
                    DispatchQueue.main.async {
                        self.LogTextView.text.append("\n *** ReBoot ***\n\n")
                    }
                }
            }
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("OTA viewWillAppear")
        
        if(ViewController.SLECT_CONTAINER_VIEW_INDEX != .OTA){
            return
        }
    }
    
    @IBAction func ScanBLE_Button(_ sender: UIButton) {
        if(ViewController._OTA_BleData?.isConnect() == true){
            _bms.cancelConnect(BLEData: ViewController._OTA_BleData!)
            self.ButtonController(isScanEnabled: true, isSelectEnabled: false, isOTAEnabled: false, isLoadIndicatorAnimating: false)
            return
        }
        
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ScanViewController") {
            self.show(controller, sender: nil)
            //self.present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func SelectBin(_ sender: UIButton) {
        
        self.ButtonController(isScanEnabled: true, isSelectEnabled: true,isOTAEnabled: false, isLoadIndicatorAnimating: false)
        
        self.LogTextView.text = ""
        
        var num = 0
        var alert = UIAlertController()
        (alert, num) = ViewController.bleFramework.SelectBin()
        if num > 0
        {
            self.present(alert, animated: true)
            let waitBinSelectQueue: DispatchQueue = DispatchQueue(label: "waitBinSelect")
            waitBinSelectQueue.async (){ ()-> Void in
                while (!ViewController.bleFramework.selectBinDone){
                    
                }
                DispatchQueue.main.async(execute: {
                    if ViewController.bleFramework.binInUse != ""
                    {
                        self.checkVersion()
                    }
                })
            }
        }else {
          
        }
    }
    
    @IBAction func StartOTA(_ sender: UIButton) {
        
        self.ButtonController(isScanEnabled: false, isSelectEnabled: false, isOTAEnabled: false, isLoadIndicatorAnimating: true)
        
        downloadFw()
    }
    
    private func checkVersion(){
        print("\n step 2 > CheckVersion")

        ViewController.bleFramework.CheckVersion()
        let checkVersionQueue: DispatchQueue = DispatchQueue(label: "checkVersion")
        checkVersionQueue.async (){ ()-> Void in
            while (ViewController.bleFramework.fotaInUse){
                
            }
            DispatchQueue.main.async(execute: {
                if ViewController.bleFramework.checkVersionGoNext
                {
                    //會進來代表，該選擇的ＢＩＮ可以更新
                    self.ButtonController(isScanEnabled: true, isSelectEnabled: true,isOTAEnabled: true, isLoadIndicatorAnimating: false)
                    
                }
                print(ViewController.bleFramework.log)
                self.LogTextView.text.append(ViewController.bleFramework.log)
                
                self.checkBank1()
                
            })
        }
    }
    private func checkBank1(){
        print("\n step 3 > checkBank1")

        ViewController.bleFramework.CheckBank1State()
        let checkBank1Queue: DispatchQueue = DispatchQueue(label: "checkBank1")
        checkBank1Queue.async (){ ()-> Void in
            while (ViewController.bleFramework.fotaInUse){
                
            }
            DispatchQueue.main.async(execute: {
                if ViewController.bleFramework.checkBank1GoNext
                {

                }
            })
        }
    }
    private func downloadFw(){
        print("\n step 4 > downloadFw")
        
        ViewController.bleFramework.DownloadFW()
        let downloadFwQueue: DispatchQueue = DispatchQueue(label: "downloadFw")
        downloadFwQueue.async (){ ()-> Void in
            while (ViewController.bleFramework.fotaInUse){
                print("OTA ing...")
                DispatchQueue.main.async {
                    self.LogTextView.text.append("\n *** OTA ing... ***")
                }
                sleep(3)
            }
            DispatchQueue.main.async(execute: {
                if ViewController.bleFramework.downloadFwGoNext
                {
                    self.crcCheckAndReboot()
                }

            })
        }
    }
    private func crcCheckAndReboot(){
        print("\n step 5 > crcCheckAndReboot")
        
        ViewController.bleFramework.ApplyReboot()
        let applyRebootQueue: DispatchQueue = DispatchQueue(label: "applyReboot")
        applyRebootQueue.async (){ ()-> Void in
            while (ViewController.bleFramework.fotaInUse){
                self._isOTA_Over = true
            }
            DispatchQueue.main.async(execute: {

            })
        }
    }
    
    /**藍芽連線*/
    @objc func ConnectBLE(notification: NSNotification) {
        
        if let fieldEditor = notification.userInfo?["From"] as? MenuEnum {
            let bleData = notification.object as! BLEData
            
            if(fieldEditor != .OTA){
                return
            }
            
            ViewController._OTA_BleData = bleData
            _bms.startConnect(BLEData: ViewController._OTA_BleData!)
            
            ViewController.bleFramework.peripheralInUse = bleData.peripheral!
            
        }
    }
    
    private func UpdateView(){
        DispatchQueue.main.async {
            self.BleDeviceNameLabel.text = "BLE Device：\(ViewController._OTA_BleData?.disPlayName ?? "none")"
            
            if(ViewController._OTA_BleData?.isConnect() == true){
                self.ScanBleButton.setTitle("DisConnect", for: .normal)
                self.ScanBleButton.setTitleColor(.red, for: .normal)
                self.BleStatusLabel.textColor = UIColor.green
                
            }else{
                self.ScanBleButton.setTitle("Scan BLE", for: .normal)
                self.ScanBleButton.setTitleColor(.white, for: .normal)
                self.BleStatusLabel.textColor = UIColor.red
            }
            
            self.BleStatusLabel.text = "BLE Status：\(self._status)"
        }
    }
    
    private func ButtonController(isScanEnabled:Bool?,isSelectEnabled:Bool?,isOTAEnabled:Bool?,isLoadIndicatorAnimating:Bool){
        DispatchQueue.main.async {
            //ScanBleButton
            if(isScanEnabled == true){
                self.ScanBleButton.isEnabled = true
                self.ScanBleButton.backgroundColor = .systemIndigo
            }
            if(isScanEnabled == false){
                self.ScanBleButton.isEnabled = false
                self.ScanBleButton.backgroundColor = .gray
            }
            //SelectBinButton
            if(isSelectEnabled == true){
                self.SelectBinButton.isEnabled = true
                self.SelectBinButton.backgroundColor = .systemIndigo
            }
            if(isSelectEnabled == false){
                self.SelectBinButton.isEnabled = false
                self.SelectBinButton.backgroundColor = .gray
            }
            //StartOTAButton
            if(isOTAEnabled == true){
                self.StartOTAButton.isEnabled = true
                self.StartOTAButton.backgroundColor = .systemIndigo
            }
            if(isOTAEnabled == false){
                self.StartOTAButton.isEnabled = false
                self.StartOTAButton.backgroundColor = .gray
            }
            
            if(isLoadIndicatorAnimating == true){
                self.LoadIndicator.startAnimating()
            }else{
                self.LoadIndicator.stopAnimating()
            }
        }
    }
}



//
//  LED_ViewController.swift
//  NUBLE
//
//  Created by WPHU on 2021/8/2.
//

import UIKit
import CoreBluetooth

class LED_ViewController: UIViewController {
    
    @IBOutlet weak var BleDeviceNameLabel: UILabel!
    @IBOutlet weak var BleStatusLabel: UILabel!
    @IBOutlet weak var ScanBleButton: UIButton!
    
    private var _BleData:BLEData? = nil //自己管？如果行不通再丟回去給main管吧
    private let _bms = BLEManager.sharedInstance
    private var _status:status = .none
    
    override func viewDidLoad() {
        print("LED viewDidLoad")
        super.viewDidLoad()
        //設置監聽 [從哪個功能回來]
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectBLE(notification:)), name: NSNotification.Name("ConnectBLE") , object: nil)
        
        _bms.addStatusListener { (status, peripheral) in
            
            if(self._BleData?.peripheral != peripheral){ //真的有要提高效率再來分出一層做BLECollectionManager吧
                return
            }
            self._status = status
            self.UpdateView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("LED viewWillAppear")
        
       
    }
    
    @IBAction func ScanBLE_Button(_ sender: UIButton) {
        if(_BleData?.isConnect() == true){
            _bms.cancelConnect(BLEData: _BleData!)
            return
        }
        
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ScanViewController") {
            self.show(controller, sender: nil)
            //self.present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func SendOFF_Button(_ sender: UIButton) {
        
        let c_uuid = _BleData?.getCharacteristicByUUID(UUID: BluetoothLeAttributes.NUVOTON_BLE_LED_WRITE_UUID)
        if(c_uuid == nil){
            return
        }
        _bms.writeValueForCharacteristic(valueData: [0x30], Peripheral: (_BleData?.peripheral)!, Characteristic: c_uuid!)
    }
    
    @IBAction func SendON_Button(_ sender: UIButton) {
        
        let c_uuid = _BleData?.getCharacteristicByUUID(UUID: BluetoothLeAttributes.NUVOTON_BLE_LED_WRITE_UUID)
        if(c_uuid == nil){
            return
        }
        _bms.writeValueForCharacteristic(valueData: [0x31], Peripheral: (_BleData?.peripheral)!, Characteristic: c_uuid!)
    }
    
    /**藍芽連線*/
    @objc func ConnectBLE(notification: NSNotification) {
        
        if let fieldEditor = notification.userInfo?["From"] as? MenuEnum {
            let bleData = notification.object as! BLEData
            
            if(fieldEditor != .LED){
                return
            }
            _BleData = bleData
            _bms.startConnect(BLEData: _BleData!)
            
        }
    }
    
    private func UpdateView(){
        self.BleDeviceNameLabel.text = "BLE Device：\(self._BleData?.disPlayName ?? "none")"
        
        if(_BleData?.isConnect() == true){
            ScanBleButton.setTitle("DisConnect", for: .normal)
            ScanBleButton.setTitleColor(.red, for: .normal)
            self.BleStatusLabel.textColor = UIColor.green
        }else{
            ScanBleButton.setTitle("Scan BLE", for: .normal)
            ScanBleButton.setTitleColor(.white, for: .normal)
            self.BleStatusLabel.textColor = UIColor.red
        }
        self.BleStatusLabel.text = "BLE Status：\(_status)"
    }
    
    
}

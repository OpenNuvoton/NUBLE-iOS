//
//  DataRateViewController.swift
//  NUBLE
//
//  Created by MS70MAC on 2021/9/16.
//

import UIKit
import BLEFramework
import CoreBluetooth

class DataRateViewController: UIViewController {
    
//    private var ViewController._RATE_BleData:BLEData? = nil //自己管？如果行不通再丟回去給main管吧
    private let _bms = BLEManager.sharedInstance
    private var _status:status = .none
    //是否支援藍芽5.0
    private var _hasBluetooth_5: Bool = false
    //记录 self.view 的原始 origin.y
    private var originY: CGFloat = 0
    
    @IBOutlet weak var BleDeviceNameLabel: UILabel!
    @IBOutlet weak var BleStatusLabel: UILabel!
    @IBOutlet weak var ScanBleButton: UIButton!
    @IBOutlet weak var MTU_TextField: UITextField!
    @IBOutlet weak var PacketTextField: UITextField!
    @IBOutlet weak var Indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var StartButton: UIButton!
    @IBOutlet weak var TxRxSegment: UISegmentedControl!
    @IBOutlet weak var PHY_Segment: UISegmentedControl!
    @IBOutlet weak var IntervalSegment: UISegmentedControl!
    @IBOutlet weak var MessageTextView: UITextView!
    @IBOutlet weak var ProgressBar: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //關閉元件
        self.setViewEnabled(isEnabled: false, isIndicatorStart: false)
        
        //键盘弹出监听，解决键盘挡住输入框的问题
        MTU_TextField.delegate = self
        PacketTextField.delegate = self
        self.originY = self.view.frame.origin.y
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        //設置監聽 [從哪個功能回來]
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectBLE(notification:)), name: NSNotification.Name("ConnectBLE") , object: nil)
        
        //新增BLE監聽
        _bms.addStatusListener { [self] (status, peripheral) in
            
            if(ViewController._RATE_BleData?.peripheral != peripheral){ //真的有要提高效率再來分出一層做BLECollectionManager吧
                return
            }
            
            self._status = status
            
            self.UpdateView()
            
            self.setViewEnabled(isEnabled: false, isIndicatorStart: false)
            
            if(status == .ConnectOK){
                //連線成功
                ViewController.bleFramework.peripheralInUse = peripheral
                
                ViewController.bleFramework.RegisterPeripheral(customized: true, to: peripheral);
                
                let c_write_uuid = ViewController._RATE_BleData?.getCharacteristicByUUID(UUID: BluetoothLeAttributes.DATARATE_CHARACTERISTICUUID_WRITE)
                let c_notify_uuid = ViewController._RATE_BleData?.getCharacteristicByUUID(UUID: BluetoothLeAttributes.NEW_DATARATE_CHARACTERISTICUUID_NOTIFY)
                
                if(c_write_uuid != nil){
                    ViewController.bleFramework.dataRateInUseWrite = c_write_uuid
                }
                
                if(c_notify_uuid != nil){
                    ViewController.bleFramework.dataRateInUseNotify = c_notify_uuid
                    ViewController.bleFramework.SetNotify(to: peripheral, characteristic: c_notify_uuid!, enabled: true)
                }
                
                if(c_write_uuid != nil && c_notify_uuid != nil){
                    self.setViewEnabled(isEnabled: true, isIndicatorStart: false)
                    //檢查是否支持藍牙5.0
                    let iPhoneVersion = PhoneInformation()
                    self._hasBluetooth_5 = iPhoneVersion.GetDeviceInfo()
                    if(self._hasBluetooth_5 == true){
                        self.PHY_Segment.selectedSegmentIndex = 1
                    }else{
                        self.PHY_Segment.selectedSegmentIndex = 0
                        self.setPHY(is1M: true)
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("OTA viewWillAppear")
        
        if(ViewController.SLECT_CONTAINER_VIEW_INDEX != .RATE){
            return
        }
    }
    
    @IBAction func ScanButton(_ sender: UIButton) {
        if(ViewController._RATE_BleData?.isConnect() == true){
            ViewController.bleFramework.throughput_stop_test_flag = 1
            _bms.cancelConnect(BLEData: ViewController._RATE_BleData!)
            //            self.ButtonController(isScanEnabled: true, isSelectEnabled: false, isOTAEnabled: false, isLoadIndicatorAnimating: false)
            return
        }
        
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ScanViewController") {
            self.show(controller, sender: nil)
        }
    }
    
    func getLength(length:Int) -> Int {
        
        if ViewController.bleFramework.largeMTU
        {
            if(length >= 244){
                return 244
            }
            return 20
        }else{
            if(length >= 160){
                return 244
            }
            return 20
        }
        
    }
    
    @IBAction func StartRateButton(_ sender: UIButton) {
        
        self.MessageTextView.text = ""
        
        if Int(MTU_TextField.text!) == nil{
            self.MessageTextView.text.append("\nWarning,Invaild value : Data Length.")
            return
        }
        
        let MTU_len = getLength(length: Int(MTU_TextField.text!)!)
        
        //MTU
        ViewController.bleFramework.throughput_sel_data_length = MTU_len
        ViewController.bleFramework.mtuLengthUI = MTU_TextField.text!
        //ATE MTU
        ViewController.bleFramework.atemtuLengthUI = MTU_TextField.text!
        ViewController.bleFramework.packetLength = ViewController.bleFramework.throughput_sel_data_length
        
        let packet_len = Int(PacketTextField.text!)
        
        if(packet_len == nil){
            self.MessageTextView.text.append("\nWarning,Invaild value : Packet Length.")
            return
        }
        
        if(packet_len! > 1048712){
            self.MessageTextView.text.append("\nWarning,The maximum packet length is 1048712.")
            return
        }
        
        self.setViewEnabled(isEnabled: false, isIndicatorStart: true)
        ProgressBar.setProgress(0, animated: true)
        self.MessageTextView.text.append("\n\nDataRate Start...\n\n")
        
        ViewController.bleFramework.throughput_sel_packet_length = packet_len!
        ViewController.bleFramework.throughput_stop_test_flag = 0
        ViewController.bleFramework.throughput_sel_sent_packet_interval_ms = 0
        ViewController.bleFramework.StartThroughput()
      
        
        let runQueue: DispatchQueue = DispatchQueue(label: "run")
        runQueue.async (){ ()-> Void in
            
            while (ViewController.bleFramework.throughput_testing)
            {
                sleep(2)
                print(ViewController.bleFramework.progress)
                DispatchQueue.main.async {
                    self.ProgressBar.setProgress(ViewController.bleFramework.progress, animated: true)
                }
            }
            
            DispatchQueue.main.async(execute: {
                print(ViewController.bleFramework.log)
                DispatchQueue.main.async {
                    self.MessageTextView.text.append(ViewController.bleFramework.log)
                    self.setViewEnabled(isEnabled: true, isIndicatorStart: false)
                }
            })
        }
        
    }
    
    @IBAction func TxRxSegment(_ sender: UISegmentedControl) {
        
        switch TxRxSegment.selectedSegmentIndex {
        case 1:
            ViewController.bleFramework.throughput_sel_test_type = 1
            break
        default: //case 0
            ViewController.bleFramework.throughput_sel_test_type = 0
            break
        }
    }
    
    @IBAction func PHY_Segment(_ sender: UISegmentedControl) {
        switch PHY_Segment.selectedSegmentIndex {
        case 1:
            self.setPHY(is1M: false)
            break
        default: //case 0
            
            self.setPHY(is1M: true)
            break
        }
    }
    
    @IBAction func IntervalSegment(_ sender: UISegmentedControl) {
        self.setViewEnabled(isEnabled: false, isIndicatorStart: true)
        
        switch IntervalSegment.selectedSegmentIndex {
        case 2:
            self.setConnectionInterval(interval: 90)
            
            break
        case 1:
            self.setConnectionInterval(interval: 12)
            
            break
        default: //case 0
            self.setConnectionInterval(interval: 32)
            
            
            break
        }
    }
    /**藍芽連線*/
    @objc func ConnectBLE(notification: NSNotification) {
        
        if let fieldEditor = notification.userInfo?["From"] as? MenuEnum {
            let bleData = notification.object as! BLEData
            
            if(fieldEditor != .RATE){
                return
            }
            
            self.setViewEnabled(isEnabled: false, isIndicatorStart: true)
            
            ViewController._RATE_BleData = bleData
            _bms.startConnect(BLEData: ViewController._RATE_BleData!)
            
            ViewController.bleFramework.peripheralInUse = bleData.peripheral!
            //            ViewController.bleFramework.Connect(to: ViewController.bleFramework.peripheralInUse)
            
        }
    }
    
    private func UpdateView(){
        DispatchQueue.main.async {
            self.BleDeviceNameLabel.text = "BLE Device：\(ViewController._RATE_BleData?.disPlayName ?? "none")"
            
            if(ViewController._RATE_BleData?.isConnect() == true){
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
    
    private func setViewEnabled(isEnabled:Bool , isIndicatorStart:Bool){
        DispatchQueue.main.async {
            self.TxRxSegment.isEnabled = isEnabled
            self.IntervalSegment.isEnabled = isEnabled
            self.StartButton.isEnabled = isEnabled
            self.StartButton.backgroundColor = isEnabled ? .systemIndigo : .gray
            self.PacketTextField.isEnabled = isEnabled
            self.MTU_TextField.isEnabled = isEnabled
            if(self._hasBluetooth_5 == true){
                self.PHY_Segment.isEnabled = isEnabled
            }else{
                self.PHY_Segment.isEnabled = false
            }
            
            isIndicatorStart ? self.Indicator.startAnimating() : self.Indicator.stopAnimating()
   
        }
    }
    
    private func setPHY(is1M:Bool)
    {
        
        self.setViewEnabled(isEnabled: false, isIndicatorStart: true)
        
        ViewController.bleFramework.phyRate = is1M ? 1:2
        
        let setCmdQueue: DispatchQueue = DispatchQueue(label: "setCmd")
        setCmdQueue.async (){ ()-> Void in
            ViewController.bleFramework.SetCmd()
        }
        
        self.view.isUserInteractionEnabled = false
        
        let checkStatusQueue: DispatchQueue = DispatchQueue(label: "checkStatus")
        checkStatusQueue.async (){ ()-> Void in
            while (ViewController.bleFramework.setCmdStatus == 1)
            {
                
            }
            DispatchQueue.main.async(execute: {
                if (ViewController.bleFramework.setCmdStatus == -1)
                {
                    self.MessageTextView.text.append("\nError ,Please set PHY again")
                    self.setViewEnabled(isEnabled: true, isIndicatorStart: false)
                } else
                {
                    self.MessageTextView.text.append("\nSuccess ,Set PHY \(is1M ? 1:2)m")
                    self.setViewEnabled(isEnabled: true, isIndicatorStart: false)
                    self.PHY_Segment.selectedSegmentIndex = is1M ? 0:1
                }
                self.view.isUserInteractionEnabled = true
            })
        }
    }
    private func setConnectionInterval(interval:Int)
    {
        
        ViewController.bleFramework.connectionInterval = interval
        
        let setCmdQueue: DispatchQueue = DispatchQueue(label: "setCmd")
        setCmdQueue.async (){ ()-> Void in
            ViewController.bleFramework.SetCmd()
        }
        
        self.view.isUserInteractionEnabled = false
        
        let checkStatusQueue: DispatchQueue = DispatchQueue(label: "checkStatus")
        checkStatusQueue.async (){ ()-> Void in
            while (ViewController.bleFramework.setCmdStatus == 1)
            {
                
            }
            DispatchQueue.main.async(execute: {
                if (ViewController.bleFramework.setCmdStatus == -1)
                {
                    self.MessageTextView.text.append("\nError ,Please set ConnectionInterval again")
                    self.setViewEnabled(isEnabled: true, isIndicatorStart: false)
                } else
                {
                    self.MessageTextView.text.append("\nSuccess ,Set ConnectionInterval")
                    self.setViewEnabled(isEnabled: true, isIndicatorStart: false)
                }
                self.view.isUserInteractionEnabled = true
            })
        }
    }

}

extension DataRateViewController: UITextFieldDelegate {
    
    //键盘弹起
    @objc func keyboardWillAppear(notification: NSNotification) {
        // 获得软键盘的高
        let keyboardinfo = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey]
        let keyboardheight:CGFloat = (keyboardinfo as AnyObject).cgRectValue.size.height
        
        //计算输入框和软键盘的高度差
        let rect = self.MTU_TextField!.convert(self.MTU_TextField!.bounds, to: self.view)
        let y = self.view.bounds.height - rect.origin.y - self.MTU_TextField!.bounds.height - keyboardheight - 5
        
        //设置中心点偏移
        UIView.animate(withDuration: 0.5) {
            if y < 0 {
                self.view.frame.origin.y = (self.originY + y)
            }
        }
    }
    
    //键盘落下
    @objc func keyboardWillDisappear(notification:NSNotification){
        //软键盘收起的时候恢复原始偏移
        UIView.animate(withDuration: 0.5) {
            self.view.frame.origin.y = self.originY
        }
    }
    
    //设置点击软键盘return键隐藏软键盘
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        /* 開始輸入時，將輸入框實體儲存 */
        MTU_TextField = textField
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        MTU_TextField.resignFirstResponder()
        //或者 self.view?.endEditing(true)
    }
    
}

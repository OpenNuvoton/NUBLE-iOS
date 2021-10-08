//
//  UartViewController.swift
//  NUBLE
//
//  Created by WPHU on 2021/8/2.
//

import UIKit
import CoreBluetooth

class UartViewController: UIViewController {
    
    @IBOutlet weak var Send_TextField: UITextField!
    @IBOutlet weak var BleDeviceNameLabel: UILabel!
    @IBOutlet weak var BleStatusLabel: UILabel!
    @IBOutlet weak var ScanBleButton: UIButton!
    @IBOutlet weak var MessageText: UITextView!
    @IBOutlet weak var LoopSwitch: UISwitch!
    @IBOutlet weak var CRLF_Switch: UISwitch!
    @IBOutlet weak var TX_Label: UILabel!
    @IBOutlet weak var RX_Label: UILabel!
    
    
    //记录 self.view 的原始 origin.y
    private var originY: CGFloat = 0
    private var _timer = Timer()
    
    private var _BleData:BLEData? = nil //自己管？如果行不通再丟回去給main管吧
    private let _bms = BLEManager.sharedInstance
    private var _status:status = .none
    
    //
    private var _sendMessage = [[UInt8]]()
    private var _sendIndex:Int = 0
    private var _sendCBCharacteristic:CBCharacteristic?
    private var _TxDataCuont = 0
    private var _TxCharCuont = 0
    private var _RxDataCuont = 0
    private var _RxCharCuont = 0
    //
    private var _willPrintMessage:NSMutableAttributedString = NSMutableAttributedString(string: "")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MessageText.isEditable = false
        MessageText.isUserInteractionEnabled = true
        MessageText.isScrollEnabled = true
        MessageText.layoutManager.allowsNonContiguousLayout = false
        
        
        //键盘弹出监听，解决键盘挡住输入框的问题
        Send_TextField.delegate = self
        self.originY = self.view.frame.origin.y
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        //設置監聽 [從哪個功能回來]
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectBLE(notification:)), name: NSNotification.Name("ConnectBLE") , object: nil)
        
        //設置監聽 [藍芽連線狀態]
        _bms.addStatusListener { (status, peripheral) in
            
            if(self._BleData?.peripheral != peripheral){ //真的有要提高效率再來分出一層做BLECollectionManager吧
                return
            }
            if(status == .ConnectOK){
                let c_m031_uuid = self._BleData?.getCharacteristicByUUID(UUID: BluetoothLeAttributes.NUVOTON_BLE_UART_NOTIFY_M031_UUID)
                let c_m032_uuid = self._BleData?.getCharacteristicByUUID(UUID: BluetoothLeAttributes.NUVOTON_BLE_UART_NOTIFY_M032_UUID)
                
                var c_uuid:CBCharacteristic?
                
                if(c_m031_uuid != nil){
                    c_uuid = c_m031_uuid
                }
                
                if(c_m032_uuid != nil){
                    c_uuid = c_m032_uuid
                }
                
                if(c_uuid == nil){
                    return
                }
                
                self._bms.setNotifyForCharacteristic(Peripheral: (self._BleData?.peripheral)!, Characteristic: c_uuid!, Enabled: true)
            }
            if(status == .didDisconnect){
              
            }
            
            self._status = status
            self.UpdateView()

        }
        self.Get_BleNotify()
        self.Get_BleWriteCallback()
        _timer = Timer.scheduledTimer(timeInterval:0.3 , target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
    
    private func UpdateView(){
        self.BleDeviceNameLabel.text = "BLE Device：\(self._BleData?.disPlayName ?? "none")"
        
        if(_status == .ConnectOK){
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
    
    @objc func timerAction() {
        
        if(self._willPrintMessage == NSMutableAttributedString(string: "")){
            return
        }
        
        DispatchQueue.main.async {
            
            let mtat = self.MessageText.attributedText
            let mas:NSMutableAttributedString = NSMutableAttributedString(string: "")
            mas.append(mtat!)
            mas.append(self._willPrintMessage)
            
            self.MessageText.attributedText =  mas
            self._willPrintMessage = NSMutableAttributedString(string: "")
            let range = NSMakeRange(self.MessageText.text.count - 1, 0)
            self.MessageText.scrollRangeToVisible(range)
            
            self.TX_Label.text = "TX：\(self._TxDataCuont) data, \(self._TxCharCuont) char"
            self.RX_Label.text = "RX：\(self._RxDataCuont) data, \(self._RxCharCuont) char"
            
        }
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
    
    @IBAction func Loop_Switch(_ sender: UISwitch) {
        if(LoopSwitch.isOn){
            CRLF_Switch.setOn(false, animated: true)
        }else{
            
        }
    }
    @IBAction func CRLF_Switch(_ sender: UISwitch) {
        if(CRLF_Switch.isOn){
            LoopSwitch.setOn(false, animated: true)
        }else{
            
        }
    }
    @IBAction func Clear_Button(_ sender: UIButton) {
        MessageText.text = ""
        _TxDataCuont = 0
        _TxCharCuont = 0
        _RxCharCuont = 0
        _RxDataCuont = 0
        self.TX_Label.text = "TX：0 data, 0 char"
        self.RX_Label.text = "RX：0 data, 0 char"
    }
    @IBAction func GoUp_Button(_ sender: UIButton) {
        MessageText.scrollRangeToVisible(NSMakeRange(0, 0))
    }
    @IBAction func GoDown_Button(_ sender: UIButton) {
        if MessageText.text.count > 0 {
            let location = MessageText.text.count - 1
            let bottom = NSMakeRange(location, 1)
            MessageText.scrollRangeToVisible(bottom)
        }
    }
    @IBAction func ClearText_Button(_ sender: UIButton) {
        Send_TextField.text = ""
    }
    
    @IBAction func SendMessage_Button(_ sender: UIButton) {
        
        if(_BleData?.isConnect() != true){
            return
        }
        
        if(Send_TextField.text == ""){
            return
        }
        
        self._sendCBCharacteristic = _BleData?.getCharacteristicByUUID(UUID: BluetoothLeAttributes.NUVOTON_BLE_UART_WRITE_UUID)
        if(self._sendCBCharacteristic == nil){
            return
        }
        
        let st = Send_TextField.text!
        let sm_uint8: [UInt8] = Array(st.utf8)
        
        self._sendMessage = sm_uint8.chunked(into: 20)
        
        if(CRLF_Switch.isOn == true){
            for i in 0...self._sendMessage.count-1{
                self._sendMessage[i].append(0x0d)
                self._sendMessage[i].append(0x0a)
            }
        }
        _bms.writeValueForCharacteristic(valueData: self._sendMessage[0], Peripheral: (_BleData?.peripheral)!, Characteristic: self._sendCBCharacteristic!)
    }
    
    /**藍芽連線*/
    @objc func ConnectBLE(notification: NSNotification) {
        
        if let fieldEditor = notification.userInfo?["From"] as? MenuEnum {
            let bleData = notification.object as! BLEData
            
            if(fieldEditor != .UART){
                return
            }
            _BleData = bleData
            _bms.startConnect(BLEData: _BleData!)
        }
    }
    
    private func Get_BleNotify(){
        
        self._bms.addNotifyListener { (message, peripheral) in
            
            let date = Date()
            let formate = date.getFormattedDate(format: "mm:ss.SSS")

            // create attributed string
            let myString = "MCU -> APP:[\(formate)] " + message + "\n"
            let myAttribute = [ NSAttributedString.Key.foregroundColor: UIColor.green ]
            let myAttrString = NSAttributedString(string: myString, attributes: myAttribute)

            self._RxDataCuont = self._RxDataCuont + 1
            self._RxCharCuont = self._RxCharCuont + message.count
            self._willPrintMessage.append(myAttrString)
        }
    }
    
    private func Get_BleWriteCallback(){
        
        self._bms.addWriteListener { (bool, peripheral) in
            
            if(self._BleData?.peripheral != peripheral){
                return
            }
            
            let message =  String(decoding: self._sendMessage[self._sendIndex], as: UTF8.self)
            
            let date = Date()
            let formate = date.getFormattedDate(format: "mm:ss.SSS")
            
            if(bool == true){
                // create attributed string
                let myString = "APP -> MCU:[\(formate)] " + message + "\n"
                let myAttribute = [ NSAttributedString.Key.foregroundColor: UIColor.blue ]
                let myAttrString = NSAttributedString(string: myString, attributes: myAttribute)

                self._willPrintMessage.append(myAttrString)
//                self.MessageText.text.append(message + "\n")
                self._TxDataCuont = self._TxDataCuont + 1
                self._TxCharCuont = self._TxCharCuont + message.count
            }else{
                // create attributed string
                let myString = "APP -> MCU:[\(formate)] " + message + "fail  \n"
                let myAttribute = [ NSAttributedString.Key.foregroundColor: UIColor.red ]
                let myAttrString = NSAttributedString(string: myString, attributes: myAttribute)

                self._willPrintMessage.append(myAttrString)
//                self.MessageText.text.append(message + "fail  \n")
            }
            
            self._sendIndex = self._sendIndex + 1
            
            if(self._sendIndex < self._sendMessage.count ){
                //繼續  送出流程
                if(self._sendCBCharacteristic == nil){
                    return
                }
                
                self._bms.writeValueForCharacteristic(valueData: self._sendMessage[self._sendIndex], Peripheral: (self._BleData?.peripheral)!, Characteristic: self._sendCBCharacteristic!)
            }else{
                //結束  送出流程
                
                self._sendIndex = 0
                if(self.LoopSwitch.isOn == true){
                    self._bms.writeValueForCharacteristic(valueData: self._sendMessage[0], Peripheral: (self._BleData?.peripheral)!, Characteristic: self._sendCBCharacteristic!)
                    return
                }
                
            }
        }
    }
    
    private func NormalWrite(addCRLF:Bool){
        
    }
    private func LoopWrite(){
        
    }
    
    
    
    
    
    //    private var NotifyListener =  { (string:String, peripheral:Any) in
    //        print(string)
    //    }
    
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
extension UartViewController: UITextFieldDelegate {
    
    //键盘弹起
    @objc func keyboardWillAppear(notification: NSNotification) {
        // 获得软键盘的高
        let keyboardinfo = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey]
        let keyboardheight:CGFloat = (keyboardinfo as AnyObject).cgRectValue.size.height
        
        //计算输入框和软键盘的高度差
        let rect = self.Send_TextField!.convert(self.Send_TextField!.bounds, to: self.view)
        let y = self.view.bounds.height - rect.origin.y - self.Send_TextField!.bounds.height - keyboardheight
        
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
        Send_TextField = textField
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        Send_TextField.resignFirstResponder()
        //或者 self.view?.endEditing(true)
    }
    
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Date {
   func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

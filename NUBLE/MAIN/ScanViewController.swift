//
//  ScanViewController.swift
//  NUBLE
//
//  Created by WPHU on 2021/8/3.
//

import UIKit
import CoreBluetooth

class ScanViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var ScanTableView: UITableView!
    private var _peripherals = [CBPeripheral]()
//    private var _kCBAdvDataManufacturerDatas = [String]()
//    private var _kCBAdvDataLocalNames = [String]()
    private var _advertisementDatas = [[String : Any]]()
    
    
    let _bm = BLEManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _peripherals.removeAll()
        _advertisementDatas.removeAll()
        
        ScanTableView.delegate = self
        ScanTableView.dataSource = self
        ScanTableView.rowHeight = 110
        
        _bm.startScan(second: nil) { (peripheral, advertisementData) in
            
            
            
//            let kCBAdvDataManufacturerDataString = String.init(format: "%@", advertisementData["kCBAdvDataManufacturerData"] as? CVarArg ?? "")
//                .replacingOccurrences(of: " ", with: "")
//                .replacingOccurrences(of: "<", with: "")
//                .replacingOccurrences(of: ">", with: "")
            let kCBAdvDataManufacturerDataString = String(describing: advertisementData["kCBAdvDataManufacturerData"] ?? "null")
            let kCBAdvDataLocalNameString = String(describing: advertisementData["kCBAdvDataLocalName"] ?? "null")
 
            print("SacnCBPeripheralName:\(String(describing: peripheral.name)),\(advertisementData)")
            print("kCBAdvDataLocalName:\(kCBAdvDataLocalNameString)")
            print("kCBAdvDataManufacturerDataString:\(kCBAdvDataManufacturerDataString)")
            
            if(self._peripherals.contains(peripheral) || peripheral.name == nil || kCBAdvDataLocalNameString == "null"){
                return
            }
            
            self._peripherals.append(peripheral)
            self._advertisementDatas.append(advertisementData)
            
            DispatchQueue.main.async {
                self.ScanTableView.reloadData()
            }
        }
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        _bm.stopScan()
    }
    
    /**有幾個cell*/
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self._peripherals.count
    }
    
    /**每個cell內容*/
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanViewCell") as! ScanViewCell
        
        let advertisementData = _advertisementDatas[indexPath.item]
        
        cell.PeripheralName.text = String(describing: advertisementData["kCBAdvDataLocalName"] ?? "null")
        cell.ManufacturerData.text = String(describing: advertisementData["kCBAdvDataManufacturerData"] ?? "null")
        
        return cell
    }
    
    /**點選cell*/
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //廣播出去 "ConnectBLE"
        let bleData = BLEData(Peripheral: _peripherals[indexPath.item],advertisementData: _advertisementDatas[indexPath.item])
        NotificationCenter.default.post(name: Notification.Name("ConnectBLE"), object: bleData,userInfo: ["From": ViewController.SLECT_CONTAINER_VIEW_INDEX])
        //關閉頁面
        self.navigationController?.popViewController(animated: true)
    }
}

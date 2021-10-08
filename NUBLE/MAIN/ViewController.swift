//
//  ViewController.swift
//  NUBLE
//
//  Created by WPHU on 2021/7/20.
//

import UIKit
import CoreBluetooth
import BLEFramework

class ViewController: UIViewController {
    
    @IBOutlet var ContainerViews: [UIView]!
    
    public static var SLECT_CONTAINER_VIEW_INDEX :MenuEnum = .UART
    public static var SELF = self
    let _bms = BLEManager.sharedInstance
    public static var bleFramework : BLEFramework!
    
    //    private static var _UART_BleData:BLEData? = nil
    //    private static var _LED_BleData:BLEData? = nil
    public static var _OTA_BleData:BLEData? = nil
    public static var _RATE_BleData:BLEData? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController viewDidLoad")
        
        self.slectContainerViews(index: ViewController.SLECT_CONTAINER_VIEW_INDEX)
        
        //啟用藍芽
        _bms.setUp()
        ViewController.bleFramework = BLEFramework()
        print(ViewController.bleFramework.GetVersion())
        ViewController.bleFramework.Initialize()
        let iPhoneVersion = PhoneInformation()
        ViewController.bleFramework.largeMTU = iPhoneVersion.GetDeviceInfo()
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            ViewController.version()
            }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("ViewController viewWillAppear")
        self.slectContainerViews(index: ViewController.SLECT_CONTAINER_VIEW_INDEX)
    }
    
    @IBAction func MenuItem(_ sender: UIBarButtonItem) {
        
        if(ViewController.SLECT_CONTAINER_VIEW_INDEX == .UART){
            if let controller = self.storyboard?.instantiateViewController(withIdentifier: "MenuViewController") {
                self.show(controller, sender: nil)
                //self.present(controller, animated: true, completion: nil)
            }
            return
        }
        
        if(ViewController.SLECT_CONTAINER_VIEW_INDEX == .LED){
            if let controller = self.storyboard?.instantiateViewController(withIdentifier: "MenuViewController") {
                self.show(controller, sender: nil)
                //self.present(controller, animated: true, completion: nil)
            }
            return
        }
        
        if(ViewController.SLECT_CONTAINER_VIEW_INDEX == .OTA){
            
            if(ViewController._OTA_BleData?.isConnect() == false || ViewController._OTA_BleData == nil){
                if let controller = self.storyboard?.instantiateViewController(withIdentifier: "MenuViewController") {
                    self.show(controller, sender: nil)
                    return
                }
                return
            }
            
            let controller = UIAlertController(title: "Leave will disconnect this function", message: "", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Leave", style: .default) { _ in
                if let controller = self.storyboard?.instantiateViewController(withIdentifier: "MenuViewController") {
                    self.show(controller, sender: nil)
                    self._bms.cancelConnect(BLEData: ViewController._OTA_BleData!)
                    return
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { _ in
             return
            }
            controller.addAction(okAction)
            controller.addAction(cancelAction)
            present(controller, animated: true, completion: nil)
        }
        
        if(ViewController.SLECT_CONTAINER_VIEW_INDEX == .RATE ){
            
            if(ViewController._RATE_BleData?.isConnect() == false || ViewController._RATE_BleData == nil){
                if let controller = self.storyboard?.instantiateViewController(withIdentifier: "MenuViewController") {
                    self.show(controller, sender: nil)
                    return
                }
                return
            }
            
            let controller = UIAlertController(title: "Leave will disconnect this function", message: "", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Leave", style: .default) { _ in
                if let controller = self.storyboard?.instantiateViewController(withIdentifier: "MenuViewController") {
                    self.show(controller, sender: nil)
                    self._bms.cancelConnect(BLEData: ViewController._RATE_BleData!)
                    return
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { _ in
                return
            }
            controller.addAction(okAction)
            controller.addAction(cancelAction)
            present(controller, animated: true, completion: nil)  
        }
    }
    
    func slectContainerViews(index:MenuEnum) {
        DispatchQueue.main.async {
            switch(index){
            case .LED:
                self.ContainerViews[0].isHidden = true
                self.ContainerViews[1].isHidden = false
                self.ContainerViews[2].isHidden = true
                self.ContainerViews[3].isHidden = true
                self.title = "TRSP LED"
            case .OTA:
                self.ContainerViews[0].isHidden = true
                self.ContainerViews[1].isHidden = true
                self.ContainerViews[2].isHidden = false
                self.ContainerViews[3].isHidden = true
                self.title = "OTA"
            case .RATE:
                self.ContainerViews[0].isHidden = true
                self.ContainerViews[1].isHidden = true
                self.ContainerViews[2].isHidden = true
                self.ContainerViews[3].isHidden = false
                self.title = "Data Rate"
            default: //case 0
                self.ContainerViews[0].isHidden = false
                self.ContainerViews[1].isHidden = true
                self.ContainerViews[2].isHidden = true
                self.ContainerViews[3].isHidden = true
                self.title = "TRSP UART"
            }
        }
    }
}


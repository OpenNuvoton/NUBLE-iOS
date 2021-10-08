//  BLEData.swift
//
//  Created by WPHU on 2018/1/19.
//  Copyright © 2018年 MacPro@kawa. All rights reserved.
//

import UIKit
import CoreBluetooth

//------------------------------------------------------------------------------------------

class BLEData :NSObject {

    init(Peripheral:CBPeripheral,advertisementData:[String : Any]) {
        self.peripheral = Peripheral
        self.disPlayName = String(describing: advertisementData["kCBAdvDataLocalName"] ?? "null")
    }
    
    var peripheral:CBPeripheral?
    var services:[serviceData] = [serviceData]()
    var MAC:String? = nil
    var servicesUUID:[CBUUID] = [CBUUID()]
    var disPlayName:String = "null"
    
    public func getCharacteristicByUUID(UUID:String) -> CBCharacteristic? {
        for s in services{
            for c in s.Characteristics{
                if c.Characteristic?.uuid.uuidString == UUID {
                    return c.Characteristic
                }
            }
        }
        return nil
    }
    
    //藍芽是否連線
    public func isConnect() -> Bool{
        if(self.peripheral?.state.rawValue == 0){
            return false
        }else  if(self.peripheral?.state.rawValue == 1){
            return false
        }else  if(self.peripheral?.state.rawValue == 2){
            return true
        }else  if(self.peripheral?.state.rawValue == 3){
            return false
        }
        return false
    }
}

class serviceData{
    var service:CBService?
    var Characteristics:[CharacteristicData] = [CharacteristicData]()
    var serviceUUID:CBUUID = CBUUID()
}

struct CharacteristicData{
    var Characteristic:CBCharacteristic?
    var CharacteristicUUID:CBUUID = CBUUID()
}

//------------------------------------------------------------------------------------------




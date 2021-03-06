//
//  BluetoothLeAttributes.swift
//
//  Created by WPHU on 2018/4/10.
//  Copyright © 2018年 MacPro@kawa. All rights reserved.
//

import UIKit

class BluetoothLeAttributes: NSObject {
    
    //UART
    public static let NUVOTON_BLE_UART_WRITE_UUID = "50515253-5455-5657-5859-5A5B5C5D5E5F";
    public static let NUVOTON_BLE_UART_NOTIFY_M031_UUID = "30313233-3435-3637-3839-3A3B3C3D3E3F";
    public static let NUVOTON_BLE_UART_NOTIFY_M032_UUID = "FA02";
    
    //LED
    public static let NUVOTON_BLE_LED_WRITE_UUID = "50515253-5455-5657-5859-5A5B5C5D5E5F";
    
    //OTA
    public static let FOTASERVICEUUID = "FEBA"
    public static let FOTACHARACTERISTICUUID_WRITENORESPONSE_NOTIFY = "FA10"
    public static let FOTACHARACTERISTICUUID_WRITE_INDICATE = "FA11"
    
    public static let NEW_FOTASERVICEUUID = "09102132-4354-6576-8798-A9BACBDCEDFE"
    public static let NEW_FOTACHARACTERISTICUUID_WRITENORESPONSE_NOTIFY = "01112131-4151-6171-8191-A1B1C1D1E1F1"
    public static let NEW_FOTACHARACTERISTICUUID_WRITE_INDICATE = "02122232-4252-6272-8292-A2B2C2D2E2F2"

    //DataRate
    private let DATARATE_SERVICEUUID = "00112233-4455-6677-8899-AABBCCDDEEFF"
//    private let THROUGHPUT_CHARACTERISTICUUID_WRITE_AT_CMD = "50515253-5455-5657-5859-5A5B5C5D5E5F"
    public static let DATARATE_CHARACTERISTICUUID_WRITE =       "50515253-5455-5657-5859-5A5B5C5D5E5F"
    private let DATARATE_CHARACTERISTICUUID_NOTIFY = "FA02"
    public static let NEW_DATARATE_CHARACTERISTICUUID_NOTIFY = "30313233-3435-3637-3839-3A3B3C3D3E3F"
    
    private let OLD_DATARATE_SERVICEUUID = "00005301-0000-0041-4C50-574953450000"
    private let OLD_DATARATE_CHARACTERISTICUUID_WRITE =       "00005302-0000-0041-4C50-574953450000"
    private let OLD_DATARATE_CHARACTERISTICUUID_NOTIFY = "00005303-0000-0041-4C50-574953450000"
    
}

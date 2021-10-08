//
//  PhoneInformation.swift
//  BLEScanner
//
//  Created by rafael_sw on 2021/4/20.
//

import Foundation
import UIKit

extension UIDevice {
    var modelName : String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror (reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce(""){identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPhone7,1" : return "iPhone 6 Plus"
        case "iPhone7,2" : return "iPhone 6"
        case "iPhone8,1" : return "iPhone 6s"
        case "iPhone8,2" : return "iPhone 6s plus"
        case "iPhone8,4" : return "iPhone SE"
        case "iPhone9,1", "iPhone9,3" : return "iPhone 7"
        case "iPhone9,2", "iPhone9,4" : return "iPhone 7 plus"
        case "iPhone10,1", "iPhone10,4" : return "iPhone 8"
        case "iPhone10,2", "iPhone10,5" : return "iPhone 8 plus"
        case "iPhone10,3", "iPhone10,6" : return "iPhone X"
        case "iPhone11,8" : return "iPhone XR"
        case "iPhone11,2" : return "iPhone XS"
        case "iPhone11,4", "iPhone11,6" : return "iPhone XS Max"
        case "iPhone12,1" : return "iPhone 11"
        case "iPhone12,3" : return "iPhone 11 Pro"
        case "iPhone12,5" : return "iPhone 11 Pro Max"
        case "iPhone12,8" : return "iPhone SE2"
        case "iPhone13,1" : return "iPhone 12 mini"
        case "iPhone13,2" : return "iPhone 12"
        case "iPhone13,3" : return "iPhone 12 Pro"
        case "iPhone13,4" : return "iPhone 12 Pro Max"
        default : return identifier
        }
    }
}

class PhoneInformation: UIViewController {
    // --------------------------------------------------------------
    // MARK: LIFECYCLE OF VIEWCONTROLLER
    // --------------------------------------------------------------
    private var phoneVersion = true
    @IBOutlet weak var phoneInfo: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        DeviceInfo()
    }
    
    private func DeviceInfo()
    {
        let iosVersion = UIDevice.current.systemVersion
        let systemName = UIDevice.current.systemName
        let modelName = UIDevice.current.modelName
        phoneInfo.textAlignment = .center
        phoneInfo.numberOfLines = 0
        phoneInfo.lineBreakMode = NSLineBreakMode.byWordWrapping
        var info = "system version: " + systemName + " " + iosVersion + "\n"
        info += "model: " + modelName + "\n"
        info += "app version: 1.0.2\n"
        info += "release date: 2021/08/13\n"
        phoneInfo.text = info
        //print(phoneInfo.text!)
    }
    
    public func GetDeviceInfo()->Bool
    {
        let modelName = UIDevice.current.modelName
        if modelName == "iPhone 6 Plus" || modelName == "iPhone 6" || modelName == "iPhone 6s" || modelName == "iPhone 6s plus" || modelName == "iPhone SE" || modelName == "iPhone 7"
        {
            return false
        }
        return true
    }
}

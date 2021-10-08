//
//  MenuViewController.swift
//  NUBLE
//
//  Created by WPHU on 2021/8/2.
//

import UIKit

class MenuViewController: UIViewController {
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        // Do any additional setup after loading the view.
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "version:\(version)"
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
    }
    
    @IBAction func UART_BUTTON(_ sender: UIButton) {
//        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as? ViewController{
//            ViewController._slectContainerViews = 0
//        }
        ViewController.SLECT_CONTAINER_VIEW_INDEX = .UART
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func LED_BUTTON(_ sender: UIButton) {
        ViewController.SLECT_CONTAINER_VIEW_INDEX = .LED
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func OTA_BUTTON(_ sender: UIButton) {
        ViewController.SLECT_CONTAINER_VIEW_INDEX = .OTA
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func Rate_BUTTON(_ sender: UIButton) {
        
        ViewController.SLECT_CONTAINER_VIEW_INDEX = .RATE
        self.navigationController?.popViewController(animated: true)
        
//        let controller = UIAlertController(title: "此功能尚未開放", message: "", preferredStyle: .alert)
//        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
//         controller.addAction(okAction)
//         present(controller, animated: true, completion: nil)
    }
}

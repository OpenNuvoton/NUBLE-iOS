//
//  ScanViewCell.swift
//  NUBLE
//
//  Created by WPHU on 2021/8/3.
//

import UIKit

class ScanViewCell: UITableViewCell {
    
    @IBOutlet weak var PeripheralName: UILabel!
    @IBOutlet weak var ManufacturerData: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

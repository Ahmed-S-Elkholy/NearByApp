//
//  PlaceTableViewCell.swift
//  NearByApp
//
//  Created by kholy on 7/18/20.
//  Copyright © 2020 kholy. All rights reserved.
//

import UIKit
import Kingfisher

class PlaceTableViewCell: UITableViewCell {

    @IBOutlet weak var placeView: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var img: UIImageView!
    
    var place : Place?{
        didSet{
            self.name.text = self.place?.name
            self.address.text = self.place?.address
            if place?.imgUrl.count ?? 0 > 0{
                self.img.kf.setImage(with: URL(string: place!.imgUrl))
            }else{
                self.img.image = UIImage(named: "location")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}

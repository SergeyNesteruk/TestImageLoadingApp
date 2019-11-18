//
//  ImageTableCellTableViewCell.swift
//  ImageLoadingApp
//
//  Created by Sergii Nesteruk on 10/10/19.
//  Copyright © 2019 NLab. All rights reserved.
//

import UIKit

class ImageTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ImageTableCellTableViewCell"
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    
    private var requestedURL: URL?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        spinnerView.isHidden = true
    }
    
    func configure(for imageModel: ImageModel) {
        nameLabel.text = imageModel.name
        spinnerView.isHidden = false
        spinnerView.startAnimating()
        if imageModel.imageURL != requestedURL {
            myImageView.image = nil
        }
        requestedURL = imageModel.imageURL
        let urlToLoad = imageModel.imageURL
        myImageView.backgroundColor = UIColor.clear
        ImageLoader.instance.getImage(from: imageModel.imageURL) { (image) in
            DispatchQueue.main.async {
                defer {
                    self.spinnerView.stopAnimating()
                    self.spinnerView.isHidden = true
                }
                guard let image = image else {
                    self.myImageView.backgroundColor = UIColor.gray
                    return
                }
                
                self.myImageView.image = image
            }
        }
    }
}

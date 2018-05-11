//
//  PhotosViewController.swift
//  AvatarTool
//
//  Created by Admin on 19/02/2018.
//  Copyright © 2018 Audrius Visniauskas. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MBProgressHUD
import AlamofireImage

class PhotosViewController: UIViewController, CropViewControllerDelegate {

    @IBOutlet weak var btnApprove: UIButton!
    @IBOutlet weak var btnDecline: UIButton!
    @IBOutlet weak var btnSkip: UIButton!
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    var Array_photoID = [String]()
    var Array_photoURL = [String]()
    var Array_photoData = [UIImage]()
    
    var index = Int()
    var pagenum = Int()
    
    var total_photoCount = Int()
    var download_photoIndex = Int()
    
    var isDisplayPhoto = Bool()
    var hub = MBProgressHUD()
    
    var download_timer = Timer()
    
    private var croppingStyle = CropViewCroppingStyle.default
    private var croppedRect = CGRect.zero
    private var croppedAngle = 0
    private var originalImageRect = CGRect.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden =  false
        self.title = "PHOTO"
        self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedStringKey.font: UIFont(name: "Arial", size: 30.0)!];

        index = 0
        pagenum = 0
        total_photoCount = 0
        download_photoIndex = 0
        
        isDisplayPhoto = false
        
        // Do any additional setup after loading the view.
        hub = MBProgressHUD.showAdded(to: view, animated: true)
        hub.label.text = "Loading Photos..."
        self.getPhotosInfo(pagenum: pagenum)
        
        
        imageView.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(didTapImageView))
        imageView.addGestureRecognizer(tapRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displayImageInImageView(image:UIImage){
        self.imageView.image = image
    }

    @IBAction func onApprove(_ sender: Any) {
        self.API_Approve()
    }
    
    @IBAction func onDecline(_ sender: Any) {
        self.API_Decline()
    }
    
    @IBAction func onSkip(_ sender: Any) {
        self.showNextPhoto()
    }
    
    func getPhotosInfo(pagenum : Int) {
        
        Alamofire.request(LB_IP+"apiKey="+API_KEY+"&method=photos&page="+String(format : "%i", pagenum)).responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let swiftyJsonVar = JSON(responseData.result.value!)
                if swiftyJsonVar["status"] == "success" {
                    //Save Data
                    if swiftyJsonVar["users"].count == 0 {
                        self.total_photoCount = self.Array_photoURL.count
                        self.downloadPhotos()
                        print(self.total_photoCount)
                    } else {
                        for i in 0..<swiftyJsonVar["users"].count {
                            self.Array_photoID.append(swiftyJsonVar["users"][i]["photoid"].string!)
                            self.Array_photoURL.append(swiftyJsonVar["users"][i]["original"].string!)
                        }
                        self.pagenum = self.pagenum + 1
                        self.getPhotosInfo(pagenum: self.pagenum)
                    }
                } else {
                    print("error")
                }
            }
        }
    }
    
    func downloadPhotos() {
        if self.total_photoCount == 0 {
            DispatchQueue.main.async {
                self.hub.hide(animated: true)
            }
            btnApprove.isEnabled = false
            btnDecline.isEnabled = false
            
            let alert = UIAlertController(title: "", message: "There is not exist any other waiting review photo.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.savePhotosData(index: self.download_photoIndex)
        }
        
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    func savePhotosData(index : Int) {
        if self.download_photoIndex < self.total_photoCount {
            getDataFromUrl(url: URL(string: self.Array_photoURL[index])!) { data, response, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async() {
                    self.Array_photoData.append(UIImage(data: data)!)
                    if self.isDisplayPhoto == false {
                        self.hub.hide(animated: true)
                        self.isDisplayPhoto = true
                        self.displayPhoto(ind: self.download_photoIndex)
                    }
                    self.download_photoIndex = self.download_photoIndex + 1
                    print("downloaded")
                    self.savePhotosData(index: self.download_photoIndex)
                }
            }
        }
        
    }

    func displayPhoto(ind : Int) {
        print("should be displayed ===  \(self.Array_photoURL[ind])")
        print("width ,height == \(self.Array_photoData[ind].size.width), \(self.Array_photoData[ind].size.height)")
        self.displayImageInImageView(image: self.Array_photoData[ind])
        self.originalImageRect = CGRect(x:0, y:0, width:self.Array_photoData[ind].size.width, height:self.Array_photoData[ind].size.height)
    }
    
    func showNextPhoto() {
        if self.index < self.Array_photoData.count-1  {
            self.index = self.index + 1
            if self.index == self.total_photoCount-1 {
                btnSkip.isEnabled = false
            }
            originalImageRect = CGRect.zero
            self.displayPhoto(ind: self.index)
        } else {
            self.isDisplayPhoto = false
            hub = MBProgressHUD.showAdded(to: view, animated: true)
            hub.label.text = ""
        }
    }
    
    func API_Approve() {
        Alamofire.request(LB_IP+"apiKey="+API_KEY+"&method=acceptphoto&photoid="+self.Array_photoID[self.index]).responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let swiftyJsonVar = JSON(responseData.result.value!)
                print("Your Photo have approved successfully!")
                print(swiftyJsonVar)
            }
        }
        if self.btnSkip.isEnabled == false {
            btnApprove.isEnabled = false
            btnDecline.isEnabled = false
            
            let alert = UIAlertController(title: "", message: "There is not exist any other waiting review photo.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.showNextPhoto()
        }
    }
    
    func API_Decline() {
        Alamofire.request(LB_IP+"apiKey="+API_KEY+"&method=declinephoto&photoid="+self.Array_photoID[self.index]).responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let swiftyJsonVar = JSON(responseData.result.value!)
                print("Your Photo have declined successfully!")
                print(swiftyJsonVar)
            }
        }
        if self.btnSkip.isEnabled == false {
            btnApprove.isEnabled = false
            btnDecline.isEnabled = false
            
            let alert = UIAlertController(title: "", message: "There is not exist any other waiting review photo.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.showNextPhoto()
        }
    }
    
    func API_Crop(newRect : CGRect, newAngle : Int) {
        let x_string = String(format : "%f", newRect.origin.x)
        let y_string = String(format : "%f", newRect.origin.y)
        let width_string = String(format : "%f", newRect.size.width)
        let height_string = String(format : "%f", newRect.size.height)
        let angle_string = String(format: "%i", newAngle)
        let scale_string = String(format: "%f", newRect.size.width/self.originalImageRect.size.width)
        print("x=\(x_string) ,y=\(y_string) ,width=\(width_string) ,height=\(height_string) ,scale=\(scale_string), angle=\(angle_string)")
        Alamofire.request(LB_IP+"apiKey="+API_KEY+"&method=cronphoto&x="+x_string+"&y="+y_string+"&h="+height_string+"&w="+width_string+"&scale="+scale_string+"&angle="+angle_string+"&photoid="+self.Array_photoID[self.index]).responseJSON { (responseData) -> Void in
            if((responseData.result.value) != nil) {
                let swiftyJsonVar = JSON(responseData.result.value!)
                print("Your Photo have cropped successfully!")
                print(swiftyJsonVar)
                print("Send approve request for this cropped photo")
                self.API_Approve()
            }
        }
    }
    
//
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @objc public func didTapImageView() {
        guard imageView.image != nil else { return }
        croppedRect = CGRect.zero
        croppedAngle = 0
        // When tapping the image view, restore the image to the previous cropping state
        let cropViewController = CropViewController(croppingStyle: self.croppingStyle, image: self.imageView.image!)
        cropViewController.delegate = self
        let viewFrame = view.convert(imageView.frame, to: navigationController!.view)
        
        cropViewController.presentAnimatedFrom(self,
                                               fromImage: self.imageView.image!,
                                               fromView: nil,
                                               fromFrame: viewFrame,
                                               angle: self.croppedAngle,
                                               toImageFrame: self.croppedRect,
                                               setup: { self.imageView.isHidden = false },
                                               completion: nil)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    //MARK: CropViewController Delegate
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.croppedRect = cropRect
        self.croppedAngle = angle
        
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    public func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        imageView.image = image
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        cropViewController.dismiss(animated: true, completion: nil)
        self.API_Crop(newRect: self.croppedRect, newAngle: self.croppedAngle)
    }
    
    
}

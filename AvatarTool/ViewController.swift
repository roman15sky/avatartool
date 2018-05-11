//
//  ViewController.swift
//  AvatarTool
//
//  Created by Admin on 19/02/2018.
//  Copyright © 2018 Audrius Visniauskas. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MBProgressHUD

class ViewController: UIViewController {
    
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        usernameTF.text = "statistic"
        passwordTF.text = "statistic"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onLogIn(_ sender: Any) {
        if usernameTF.text == "" || passwordTF.text == "" {
            return
        } else {
            self.loginService(username: usernameTF.text!, password: passwordTF.text!)
        }
    }
    
    func loginService(username: String, password : String) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.label.text = "Loading..."
        Alamofire.request(LB_IP+"apiKey="+API_KEY+"&method=login&username="+username+"&password="+password).responseJSON { (responseData) -> Void in
            hud.hide(animated: true)
            if((responseData.result.value) != nil) {
                let swiftyJsonVar = JSON(responseData.result.value!)
                if swiftyJsonVar["status"] == "success" {
                    //Save Data
                    let userDefault: UserDefaults? = UserDefaults.standard
                    userDefault?.set(swiftyJsonVar["sessname"].string, forKey: "sessname")
                    userDefault?.set(swiftyJsonVar["sessid"].string, forKey: "sessid")
                    //Go PhotoViewController
                    self.performSegue(withIdentifier: "goPhotoSegue",
                                 sender: self)
//                    let photoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotosVC")
//                    photoVC.modalTransitionStyle = .crossDissolve
//                    self.navigationController?.pushViewController(photoVC, animated: true)
                    
//                    self.present(photoVC, animated: true, completion: nil)
                } else {
                    print("error")
                }
            }
        }
    }
    
}

